module MainLobby exposing (..)

import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
import Dom.Scroll as Scroll
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html, programWithFlags)
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (..)
import MainLobbyComs exposing (..)
import MainLobbyTypes exposing (..)
import MainLobbyView exposing (..)
import Navigation exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket
import Task exposing (..)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        lobbyChat =
            initPhoenixChannel "lobby:chat"

        lobbyMainlobby =
            initPhoenixChannel "lobby:mainlobby"

        ( newSocket1, phxCmd1 ) =
            Phoenix.Socket.join lobbyChat (initialSocket flags)

        ( newSocket2, phxCmd2 ) =
            Phoenix.Socket.join lobbyMainlobby newSocket1

        phxCmd =
            Cmd.batch [ phxCmd1, phxCmd2 ]
    in
    { wsUrl = flags.wsUrl
    , authToken = flags.authToken
    , authSalt = flags.authSalt
    , phxSocket = newSocket2
    , playerInfo = defPlayer
    , log = ""
    , errors = ""
    , presences = Dict.empty
    , chatMessageInput = ""
    , chatLog = []
    , chatMessageBoxFocused = False
    , gamesMeta = Dict.empty
    , gamesSetup = Dict.empty
    , currentSelectedGame = Nothing
    , waitingForOthers = False
    }
        ! [ Cmd.map PhoenixMsg phxCmd ]


initPhoenixChannel : String -> Phoenix.Channel.Channel Msg
initPhoenixChannel topic =
    Phoenix.Channel.init topic



--|> Phoenix.Channel.onError Default
--|> Phoenix.Channel.onJoinError Default


initialSocket : Flags -> Phoenix.Socket.Socket Msg
initialSocket flags =
    let
        wsUrlWithAuth =
            flags.wsUrl
                ++ "?token="
                ++ flags.authToken
                ++ "&salt="
                ++ flags.authSalt
    in
    Phoenix.Socket.init wsUrlWithAuth
        |> Phoenix.Socket.on "greetings" "lobby:chat" ReceivePlayerInfo
        |> Phoenix.Socket.on "presence_state" "lobby:chat" ReceivePresenceState
        |> Phoenix.Socket.on "presence_diff" "lobby:chat" ReceivePresenceDiff
        |> Phoenix.Socket.on "new_chat_message" "lobby:chat" ReceiveChatMessage
        |> Phoenix.Socket.on "chat_history" "lobby:chat" UpdateChatLog
        |> Phoenix.Socket.on "games_meta" "lobby:mainlobby" ReceiveGamesMeta
        |> Phoenix.Socket.on "games_setup" "lobby:mainlobby" ReceiveGamesSetup
        |> Phoenix.Socket.on "ready_to_launch" "lobby:mainlobby" Launch
        --|> Phoenix.Socket.withoutHeartbeat
        |> Phoenix.Socket.withDebug


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ServerMsg jsonVal ->
            case Decode.decodeValue (Decode.field "content" Decode.string) jsonVal of
                Ok s ->
                    { model | log = s } ! []

                Err s ->
                    { model | errors = s } ! []

        ServerError jsonVal ->
            model ! []

        ReceivePlayerInfo jsonVal ->
            case decodePlayerInfo jsonVal of
                Ok plInf ->
                    let
                        currPlInf =
                            model.playerInfo

                        newPlInf =
                            { currPlInf | username = plInf.username }
                    in
                    { model | playerInfo = newPlInf } ! []

                Err s ->
                    { model | errors = s } ! []

        ReceivePresenceState jsonVal ->
            let
                presences =
                    decodePresenceState jsonVal
                        |> Result.map (\state -> Presence.syncState state model.presences)
            in
            case presences of
                Ok ps ->
                    { model | presences = ps } ! []

                Err e ->
                    { model | errors = e } ! []

        ReceivePresenceDiff jsonVal ->
            let
                presences =
                    decodePresenceDiff jsonVal
                        |> Result.map (\diff -> Presence.syncDiff diff model.presences)
            in
            case presences of
                Ok ps ->
                    { model | presences = ps } ! []

                Err e ->
                    { model | errors = e } ! []

        JoinChannels ->
            let
                lobbyChat =
                    initPhoenixChannel "lobby:chat"

                lobbyMainlobby =
                    initPhoenixChannel "lobby:mainlobby"

                ( newSocket1, phxCmd1 ) =
                    Phoenix.Socket.join lobbyChat model.phxSocket

                ( newSocket2, phxCmd2 ) =
                    Phoenix.Socket.join lobbyMainlobby newSocket1

                phxCmd =
                    Cmd.batch [ phxCmd1, phxCmd2 ]
            in
            { model | phxSocket = newSocket2 } ! [ Cmd.map PhoenixMsg phxCmd ]

        JoinChannel topic ->
            let
                channel =
                    initPhoenixChannel topic

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
            { model | phxSocket = newSocket } ! [ Cmd.map PhoenixMsg phxCmd ]

        LeaveChannel topic ->
            let
                ( newSocket, phxCmd ) =
                    Phoenix.Socket.leave topic model.phxSocket
            in
            { model | phxSocket = newSocket } ! [ Cmd.map PhoenixMsg phxCmd ]

        PhoenixMsg msg ->
            let
                ( newSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
            ( { model | phxSocket = newSocket }
            , Cmd.map PhoenixMsg phxCmd
            )

        ChatMessageInput message ->
            { model | chatMessageInput = message } ! []

        SendChatMessage date ->
            let
                payload =
                    encodeChatMessage
                        { message = model.chatMessageInput
                        , author = model.playerInfo
                        , timeStamp = date
                        }

                pushMsg =
                    Phoenix.Push.init "new_chat_message" "lobby:chat"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | log = "message sent"
                , phxSocket = newSocket
                , chatMessageInput = ""
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        ReceiveChatMessage jsonVal ->
            case decodeChatMessage jsonVal of
                Ok message ->
                    { model | chatLog = message :: model.chatLog }
                        ! [ attempt DropRes (Scroll.toBottom "chatLogContainer") ]

                Err e ->
                    { model | errors = e } ! []

        ReceiveGamesMeta jsonVal ->
            case decodeGamesMeta jsonVal of
                Ok gamesMeta ->
                    let
                        gamesMetaDict =
                            List.map (\gm -> ( gm.name, gm )) gamesMeta
                                |> Dict.fromList
                    in
                    { model | gamesMeta = gamesMetaDict } ! []

                Err e ->
                    { model | errors = e } ! []

        ReceiveGamesSetup jsonVal ->
            case decodeGamesSetup model jsonVal of
                Ok gamesSetup ->
                    { model | gamesSetup = gamesSetup } ! []

                Err e ->
                    { model | errors = e } ! []

        UpdateChatLog jsonVal ->
            case decodeChatHistory jsonVal of
                Ok chatHistory ->
                    { model | chatLog = chatHistory }
                        ! [ attempt DropRes (Scroll.toBottom "chatLogContainer") ]

                Err e ->
                    { model | errors = e } ! []

        FocusChatMessageBox ->
            { model | chatMessageBoxFocused = True } ! []

        UnfocusChatMessageBox ->
            { model | chatMessageBoxFocused = False } ! []

        KeyDown keycode ->
            if keycode == 13 && model.chatMessageBoxFocused then
                update (RequestDate SendChatMessage) model
            else
                model ! []

        RequestDate callback ->
            model ! [ perform callback Date.now ]

        DropRes _ ->
            model ! []

        SelectGame gameMeta ->
            { model | currentSelectedGame = Just gameMeta } ! []

        UnSelectGame ->
            { model | currentSelectedGame = Nothing } ! []

        NewGame ->
            case model.currentSelectedGame of
                Nothing ->
                    model ! []

                Just gameMeta ->
                    let
                        payload =
                            encodeNewGameMessage
                                { name = gameMeta.name
                                , host = model.playerInfo.username
                                }

                        pushMsg =
                            Phoenix.Push.init "new_game_message" "lobby:mainlobby"
                                |> Phoenix.Push.withPayload payload
                                |> Phoenix.Push.onError ServerError

                        ( newSocket, phxCmd ) =
                            Phoenix.Socket.push pushMsg model.phxSocket
                    in
                    { model
                        | log = "message sent"
                        , phxSocket = newSocket

                        --, currentlyHosting = True
                    }
                        ! [ Cmd.map PhoenixMsg phxCmd ]

        DeleteGame gameId ->
            let
                payload =
                    encodeDeleteGameMessage
                        gameId

                pushMsg =
                    Phoenix.Push.init "delete_game_message" "lobby:mainlobby"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | log = "message sent"
                , phxSocket = newSocket

                --, currentlyHosting = False
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        JoinGame gameId ->
            let
                payload =
                    encodeJoinGameMessage
                        model.playerInfo.username
                        gameId

                pushMsg =
                    Phoenix.Push.init "join_game_message" "lobby:mainlobby"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | log = "message sent"
                , phxSocket = newSocket

                --, currentlyJoining = True
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        LeaveGame gameId ->
            let
                payload =
                    encodeLeaveGameMessage
                        model.playerInfo.username
                        gameId

                pushMsg =
                    Phoenix.Push.init "leave_game_message" "lobby:mainlobby"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | log = "message sent"
                , phxSocket = newSocket

                --, currentlyJoining = False
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        StartGame gameId ->
            let
                payload =
                    encodeStartGameMessage
                        model.playerInfo.username
                        gameId

                pushMsg =
                    Phoenix.Push.init "start_game_message" "lobby:mainlobby"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | waitingForOthers = True
                , phxSocket = newSocket
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        Launch jsonVal ->
            let
                gameName =
                    Maybe.withDefault "" (Maybe.map .name model.currentSelectedGame)

                gameUrl id =
                    case gameName of
                        "hexaboard" ->
                            "/game?game_name=hexaboard&game_id=" ++ id

                        "war" ->
                            "/game?game_name=war&game_id=" ++ id

                        _ ->
                            ""
            in
            case decodeGameId model jsonVal of
                Ok ( name, id ) ->
                    model ! [ load (gameUrl (name ++ "_" ++ toString id)) ]

                Err e ->
                    { model | errors = e } ! []

        Default ->
            model ! []


subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , downs KeyDown
        ]
