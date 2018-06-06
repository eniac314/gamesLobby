module Hexaboard.HexaboardComs exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Hexaboard.HexaboardTypes exposing (..)
import Hexaboard.Board as Board
import Json.Decode as Decode
import Json.Encode as Encode
import Json.PrettyPrint as PrettyPrint
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket


decodePresenceState jsonVal =
    Decode.decodeValue
        (Presence.presenceStateDecoder presPlayerDecoder)
        jsonVal


decodePresenceDiff jsonVal =
    Decode.decodeValue
        (Presence.presenceDiffDecoder presPlayerDecoder)
        jsonVal


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage { timeStamp, author, message } =
    Encode.object
        [ ( "time_stamp", Encode.float (toTime timeStamp) )
        , ( "author", encodePlayer author )
        , ( "message", Encode.string message )
        ]


encodePlayer : PresPlayer -> Encode.Value
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
        |> Result.map (\name -> { defPresPlayer | username = name })


presPlayerDecoder =
    Decode.map2 (\j u -> { defPresPlayer | onlineAt = j, username = u })
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
        (Decode.field "author" presPlayerDecoder)
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
        gameState b ( d, id, p ) at tso po go ps =
            { board = b
            , deck = List.map (\v -> { value = v, playerId = id }) d
            , id = id
            , availableTurns = at
            , turnSelectionOrder = tso
            , piece = p
            , playingOrder = po
            , gameOver =
                go
                --, scores = s
            , players = ps
            }

        gameStateDecoder =
            Decode.field "game_state" <|
                Decode.map7 gameState
                    (Decode.field "board" decodeBoard)
                    (Decode.field "players" (playerDecoder2 player))
                    (Decode.field "available_turns" decodeAvlTurns)
                    (Decode.field "turn_selection_order" decodeTurnSelOrd)
                    (Decode.field "playing_order" decodePlayingOrder)
                    (Decode.field "game_over" Decode.bool)
                    --(Decode.field "players" decodeScores)
                    (Decode.field "players" decodePlayers)
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
        |> Decode.map (Board.boardWithEdge 6)


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


decodePlayers =
    let
        decodePiece id =
            Decode.nullable Decode.int
                |> Decode.map
                    (Maybe.map (\v -> Piece v id))

        decodePlayer =
            Decode.map4 Player
                (Decode.field "name" Decode.string)
                (Decode.field "id" Decode.int)
                (Decode.field "score" Decode.int)
                (Decode.field "id" Decode.int
                    |> Decode.andThen
                        (\id ->
                            Decode.field "piece"
                                (decodePiece id)
                        )
                )
    in
        Decode.dict decodePlayer
            |> Decode.map (Dict.values)


playerDecoder2 player =
    Decode.field player
        (Decode.map3 (,,)
            (Decode.field "deck" decodeDeck)
            (Decode.field "id" Decode.int)
            (Decode.field "piece" (Decode.nullable Decode.int))
        )


decodeDeck =
    Decode.list Decode.int


decodeScores =
    Decode.dict
        (Decode.map3 (,,)
            (Decode.field "name" Decode.string)
            (Decode.field "id" Decode.int)
            (Decode.field "score" Decode.int)
        )
        |> Decode.map Dict.values


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
