module MainLobbyComs exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import MainLobbyTypes exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage { timeStamp, author, message } =
    Encode.object
        [ ( "time_stamp", Encode.float (toTime timeStamp) )
        , ( "author", encodePlayer author )
        , ( "message", Encode.string message )
        ]


encodeNewGameMessage { name, host } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "host", Encode.string host )
        ]


encodeDeleteGameMessage ( gameMeta, id ) =
    Encode.object
        [ ( "name", Encode.string gameMeta.name )
        , ( "id", Encode.int id )
        ]


encodeJoinGameMessage player ( gameMeta, id ) =
    Encode.object
        [ ( "player", Encode.string player )
        , ( "game_id"
          , Encode.object
                [ ( "name", Encode.string gameMeta.name )
                , ( "id", Encode.int id )
                ]
          )
        ]


encodeStartGameMessage player ( gameMeta, id ) =
    Encode.object
        [ ( "player", Encode.string player )
        , ( "game_id"
          , Encode.object
                [ ( "name", Encode.string gameMeta.name )
                , ( "id", Encode.int id )
                ]
          )
        ]


encodeLeaveGameMessage player ( gameMeta, id ) =
    Encode.object
        [ ( "player", Encode.string player )
        , ( "game_id"
          , Encode.object
                [ ( "name", Encode.string gameMeta.name )
                , ( "id", Encode.int id )
                ]
          )
        ]


decodeChatMessage : Decode.Value -> Result String ChatMessage
decodeChatMessage jsonVal =
    Decode.decodeValue
        chatMessageDecoder
        jsonVal


chatMessageDecoder =
    Decode.map3 ChatMessage
        (Decode.field "time_stamp" decodeDate)
        (Decode.field "author" playerDecoder)
        (Decode.field "message" Decode.string)


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


encodePlayer : Player -> Encode.Value
encodePlayer { username, onlineAt } =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "joined_at", Encode.string onlineAt )
        ]


decodePlayerInfo jsonVal =
    Decode.decodeValue
        (Decode.field "username" Decode.string)
        jsonVal
        |> Result.map (\name -> { defPlayer | username = name })


playerDecoder =
    Decode.map2 Player
        (Decode.field "joined_at" Decode.string)
        (Decode.field "username" Decode.string)


decodePresenceState jsonVal =
    Decode.decodeValue
        (Presence.presenceStateDecoder playerDecoder)
        jsonVal


decodePresenceDiff jsonVal =
    Decode.decodeValue
        (Presence.presenceDiffDecoder playerDecoder)
        jsonVal


decodeGamesMeta jsonVal =
    Decode.decodeValue
        (Decode.field "games_meta" (Decode.list gameMetaDecoder))
        jsonVal


gameMetaDecoder =
    Decode.map4 GameMeta
        (Decode.field "name" Decode.string)
        (Decode.field "min_players" Decode.int)
        (Decode.field "max_players" Decode.int)
        (Decode.field "has_ia" Decode.bool)


decodeGamesSetup model jsonVal =
    Decode.decodeValue
        (Decode.field "games_setup" (gamesSetupDecoder model))
        jsonVal


gamesSetupDecoder : Model -> Decode.Decoder (Dict String GameSetup)
gamesSetupDecoder model =
    Decode.dict (gameSetupDecoder model)


gameSetupDecoder model =
    Decode.map5 GameSetup
        (Decode.field "game_meta" gameMetaDecoder)
        (Decode.field "joined" (joinedDecoder model))
        (Decode.field "has_started" (hasStartedDecoder model))
        (Decode.field "host" (hostDecoder model))
        (Decode.field "game_id" (gameIdDecoder model))


hostDecoder model =
    Decode.string
        |> Decode.andThen
            (\h -> Decode.succeed <| Just h)



--    if Dict.member h model.presences then
--        Decode.succeed (Just h)
--    else
--        Decode.succeed Nothing
--)


joinedDecoder model =
    Decode.list
        (Decode.string
            |> Decode.andThen
                (\p ->
                    if Dict.member p model.presences then
                        Decode.succeed p
                    else
                        Decode.fail "invalid player name"
                )
        )


hasStartedDecoder model =
    Decode.list
        (Decode.string
            |> Decode.andThen
                (\p ->
                    if Dict.member p model.presences then
                        Decode.succeed p
                    else
                        Decode.fail "invalid player name"
                )
        )


decodeGameId model jsonVal =
    let
        gameIdDecoder =
            Decode.map2 (,)
                (Decode.field "name" Decode.string)
                (Decode.field "id" Decode.int)
    in
    Decode.decodeValue
        (Decode.field "game_id" gameIdDecoder)
        jsonVal


gameIdDecoder : Model -> Decode.Decoder GameId
gameIdDecoder model =
    Decode.map (idStrToGameId model) Decode.string
        |> Decode.andThen
            (\mv ->
                case mv of
                    Nothing ->
                        Decode.fail "invalid game id"

                    Just id ->
                        Decode.succeed id
            )


idStrToGameId model str =
    case String.split " " str of
        name :: id :: [] ->
            Dict.get name model.gamesMeta
                |> Maybe.andThen
                    (\gm ->
                        String.toInt id
                            |> Result.map (\id -> ( gm, id ))
                            |> Result.toMaybe
                    )

        _ ->
            Nothing
