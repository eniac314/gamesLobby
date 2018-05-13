module Hexaboard.HexaboardComs exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Hexaboard.HexaboardTypes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.PrettyPrint as PrettyPrint
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket


decodePresenceState jsonVal =
    Decode.decodeValue
        (Presence.presenceStateDecoder playerDecoder)
        jsonVal


decodePresenceDiff jsonVal =
    Decode.decodeValue
        (Presence.presenceDiffDecoder playerDecoder)
        jsonVal


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage { timeStamp, author, message } =
    Encode.object
        [ ( "time_stamp", Encode.float (toTime timeStamp) )
        , ( "author", encodePlayer author )
        , ( "message", Encode.string message )
        ]


encodePlayer : Player -> Encode.Value
encodePlayer { username, onlineAt } =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "joined_at", Encode.string onlineAt )
        ]


encodePickedUpPiece { value, playerId } =
    Encode.object
        [ ( "piece"
          , Encode.object
                [ ( "value", Encode.int value )
                , ( "player_id", Encode.int playerId )
                ]
          )
        , ( "player_id", Encode.int playerId )
        ]


decodePlayerInfo jsonVal =
    Decode.decodeValue
        (Decode.field "username" Decode.string)
        jsonVal
        |> Result.map (\name -> { defPlayer | username = name })


playerDecoder =
    Decode.map2 (\j u -> { defPlayer | onlineAt = j, username = u })
        (Decode.field "joined_at" Decode.string)
        (Decode.field "username" Decode.string)


decodeChatMessage : Decode.Value -> Result String ConsoleMsg
decodeChatMessage jsonVal =
    Decode.decodeValue
        chatMessageDecoder
        jsonVal


chatMessageDecoder =
    Decode.map3 ChatMessage
        (Decode.field "time_stamp" decodeDate)
        (Decode.field "author" playerDecoder)
        (Decode.field "message" Decode.string)
        |> Decode.map ChatMsg


decodeChatHistory jsonVal =
    let
        chatHistoryDecoder =
            Decode.list chatMessageDecoder
    in
    Decode.decodeValue
        (Decode.field "chat_history" chatHistoryDecoder)
        jsonVal


decodeDate =
    Decode.map
        (\v ->
            Date.fromTime v
        )
        Decode.float


decodeGameState player jsonVal =
    let
        gameState b ( d, s, id, p ) at po =
            { board = b
            , deck = List.map (\v -> { value = v, playerId = id }) d
            , score = s
            , id = id
            , availableTurns = at
            , piece = p
            , playingOrder = po
            }

        gameStateDecoder =
            Decode.field "game_state" <|
                Decode.map4 gameState
                    (Decode.field "board" decodeBoard)
                    (Decode.field "players" (playerDecoder2 player))
                    (Decode.field "available_turns" decodeAvlTurns)
                    (Decode.field "playing_order" decodePlayingOrder)
    in
    Decode.decodeValue gameStateDecoder jsonVal


decodePieceDown =
    decodeGameState


decodeBoard : Decode.Decoder Board
decodeBoard =
    Decode.list decodeCell
        |> Decode.map
            (List.foldr
                (\c acc ->
                    Dict.insert ( c.xPos, c.yPos ) c acc
                )
                Dict.empty
            )


decodeCell =
    Decode.map3 Cell
        (Decode.field "x_pos" Decode.int)
        (Decode.field "y_pos" Decode.int)
        (Decode.field "state" decodeCellState)


decodeCellState =
    let
        decodeToSumType s t =
            Decode.string
                |> Decode.andThen
                    (\v ->
                        if v == s then
                            Decode.succeed t
                        else
                            Decode.fail "wrong match"
                    )

        decodeEmpty =
            decodeToSumType "empty" Empty

        decodeContainPiece =
            Decode.field "contain" decodePiece
                |> Decode.map Contain

        decodeUnplayable =
            Decode.field "unplayable" Decode.string
                |> Decode.map (\_ -> UnPlayable Grey)
    in
    Decode.oneOf
        [ decodeEmpty
        , decodeContainPiece
        , decodeUnplayable
        ]


decodePiece =
    Decode.map2 Piece
        (Decode.field "value" Decode.int)
        (Decode.field "player_id" Decode.int)


decodeAvlTurns =
    Decode.list Decode.int


decodeTurnSelOrd =
    Decode.list Decode.int


decodePlayingOrder =
    Decode.list Decode.int


decodePlayer player =
    Decode.decodeValue <|
        Decode.field "players" (playerDecoder2 player)


playerDecoder2 player =
    Decode.field player
        (Decode.map4 (,,,)
            (Decode.field "deck" decodeDeck)
            (Decode.field "score" decodeScore)
            (Decode.field "id" Decode.int)
            (Decode.field "piece" (Decode.nullable Decode.int))
        )


decodeDeck =
    Decode.list Decode.int


decodeScore =
    Decode.int


decodeTurnsInfo jsonVal =
    let
        turnsInfo avt tso po =
            { availableTurns = avt
            , turnSelectionOrder = tso
            , playingOrder = po
            }
    in
    Decode.decodeValue
        (Decode.map3 turnsInfo
            (Decode.field "available_turns" decodeAvlTurns)
            (Decode.field "turn_selection_order" decodeTurnSelOrd)
            (Decode.field "playing_order" decodePlayingOrder)
        )
        jsonVal


debugJson getter =
    Decode.decodeValue
        (getter Decode.value
            |> Decode.map
                (PrettyPrint.toString
                 -->> PrettyPrint.stringify
                )
        )
