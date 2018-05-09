module Hexaboard exposing (..)

import AnimationFrame exposing (diffs)
import Date exposing (..)
import Dict exposing (..)
import Dom.Scroll as Scroll
import Element exposing (Device, classifyDevice)
import Hexaboard.Board exposing (..)
import Hexaboard.BoardView exposing (..)
import Hexaboard.HexaboardComs exposing (..)
import Hexaboard.HexaboardTypes exposing (..)
import Hexaboard.HexaboardView exposing (..)
import Html exposing (Html, programWithFlags)
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket
import Task exposing (attempt, perform)
import Time exposing (Time, every, second)
import Window exposing (..)


n =
    6


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
        payload =
            Encode.object [ ( "game_id", Encode.string flags.gameId ) ]

        hexaboardChat =
            initPhoenixChannel ("hexaboard:chat:" ++ flags.gameId) payload

        hexaboardGame =
            initPhoenixChannel ("hexaboard:game:" ++ flags.gameId) payload

        ( newSocket1, phxCmd1 ) =
            Phoenix.Socket.join hexaboardChat (initialSocket flags)

        ( newSocket2, phxCmd2 ) =
            Phoenix.Socket.join hexaboardGame newSocket1

        phxCmd =
            Cmd.batch [ phxCmd1, phxCmd2 ]

        defWinSize =
            { height = 768, width = 1024 }
    in
    { wsUrl = flags.wsUrl
    , authToken = flags.authToken
    , authSalt = flags.authSalt
    , gameId = flags.gameId
    , phxSocket = newSocket2
    , playerInfo = defPlayer
    , presences = Dict.empty
    , chatMessageInput = ""
    , consoleLog = []
    , chatMessageBoxFocused = False
    , board = boardWithEdge n (hexaBoard n)
    , choice = Nothing
    , turn = Nothing
    , score = 0
    , deck = []
    , gameState = PieceSelection
    , device = classifyDevice defWinSize
    , winSize = defWinSize
    }
        ! [ Cmd.map PhoenixMsg phxCmd
          , Task.perform Resizes Window.size
          ]


initPhoenixChannel : String -> Encode.Value -> Phoenix.Channel.Channel Msg
initPhoenixChannel topic payload =
    Phoenix.Channel.init topic
        |> Phoenix.Channel.withPayload payload


initialSocket : Flags -> Phoenix.Socket.Socket Msg
initialSocket flags =
    let
        wsUrlWithAuth =
            flags.wsUrl
                ++ "?token="
                ++ flags.authToken
                ++ "&salt="
                ++ flags.authSalt

        chatChannel =
            "hexaboard:chat:" ++ flags.gameId

        gameChannel =
            "hexaboard:game:" ++ flags.gameId
    in
    Phoenix.Socket.init wsUrlWithAuth
        |> Phoenix.Socket.on "greetings" chatChannel ReceivePlayerInfo
        |> Phoenix.Socket.on "greetings" gameChannel RequestGameState
        |> Phoenix.Socket.on "presence_state" chatChannel ReceivePresenceState
        |> Phoenix.Socket.on "presence_diff" chatChannel ReceivePresenceDiff
        |> Phoenix.Socket.on "new_chat_message" chatChannel ReceiveChatMessage
        |> Phoenix.Socket.on "chat_history" chatChannel UpdateChatLog
        |> Phoenix.Socket.on "game_state" gameChannel UpdateGameState
        |> Phoenix.Socket.withDebug


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( newSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
            ( { model | phxSocket = newSocket }
            , Cmd.map PhoenixMsg phxCmd
            )

        ReceivePlayerInfo jsonVal ->
            case decodePlayerInfo jsonVal of
                Ok plInf ->
                    let
                        currPlInf =
                            model.playerInfo

                        newPlInf =
                            { currPlInf | username = plInf.username }

                        newModel =
                            { model | playerInfo = newPlInf }
                    in
                    update (RequestDate <| AddServerMsg ("connexion established to game: " ++ model.gameId)) newModel

                Err s ->
                    model ! []

        FocusChatMessageBox ->
            { model | chatMessageBoxFocused = True } ! []

        UnfocusChatMessageBox ->
            { model | chatMessageBoxFocused = False } ! []

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
                    Phoenix.Push.init "new_chat_message" ("hexaboard:chat:" ++ model.gameId)
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onError ServerError

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg model.phxSocket
            in
            { model
                | phxSocket = newSocket
                , chatMessageInput = ""
            }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        RequestGameState jsonVal ->
            case decodePlayerInfo jsonVal of
                Ok plInf ->
                    let
                        currPlInf =
                            model.playerInfo

                        newPlInf =
                            { currPlInf | username = plInf.username }

                        pushMsg =
                            Phoenix.Push.init "requesting_gamestate" ("hexaboard:game:" ++ model.gameId)
                                |> Phoenix.Push.onError ServerError

                        ( newSocket, phxCmd ) =
                            Phoenix.Socket.push pushMsg model.phxSocket

                        newModel =
                            { model
                                | playerInfo = newPlInf
                                , phxSocket = newSocket
                            }
                    in
                    newModel ! [ Cmd.map PhoenixMsg phxCmd ]

                Err s ->
                    model ! []

        ReceiveChatMessage jsonVal ->
            case decodeChatMessage jsonVal of
                Ok message ->
                    { model | consoleLog = message :: model.consoleLog }
                        ! [ attempt DropRes (Scroll.toBottom "chatLogContainer") ]

                Err e ->
                    model ! []

        UpdateChatLog jsonVal ->
            case decodeChatHistory jsonVal of
                Ok chatHistory ->
                    { model | consoleLog = chatHistory }
                        ! [ attempt DropRes (Scroll.toBottom "chatLogContainer") ]

                Err e ->
                    model ! []

        KeyDown keycode ->
            if keycode == 13 && model.chatMessageBoxFocused then
                update (RequestDate SendChatMessage) model
            else
                model ! []

        UpdateGameState jsonVal ->
            case decodeGameState model.playerInfo.username jsonVal of
                Ok { board, deck, score, id, availableTurns } ->
                    let
                        plInf =
                            model.playerInfo

                        newModel =
                            { model
                                | board = board
                                , deck = deck
                                , score = score
                                , playerInfo = { plInf | playerId = id }
                            }
                    in
                    update
                        (RequestDate <| AddGameMsg "game state updated")
                        newModel

                Err e ->
                    update
                        (RequestDate <| AddServerError ("update game state - json error: " ++ e))
                        model

        PickUpPiece { value, playerId } ->
            model ! []

        RequestDate callback ->
            model ! [ perform callback Date.now ]

        Resizes size ->
            { model
                | device = classifyDevice size
                , winSize = size
            }
                ! []

        AddServerMsg msg date ->
            let
                sysMsg =
                    { timeStamp = date
                    , message = msg
                    }

                newConsoleLog =
                    ServerComMsg sysMsg :: model.consoleLog
            in
            { model | consoleLog = newConsoleLog } ! []

        AddServerError msg date ->
            let
                sysMsg =
                    { timeStamp = date
                    , message = msg
                    }

                newConsoleLog =
                    ServerErrorMsg sysMsg :: model.consoleLog
            in
            { model | consoleLog = newConsoleLog } ! []

        AddGameMsg msg date ->
            let
                sysMsg =
                    { timeStamp = date
                    , message = msg
                    }

                newConsoleLog =
                    GameMsg sysMsg :: model.consoleLog
            in
            { model | consoleLog = newConsoleLog } ! []

        DebugJson getter jsonVal ->
            case debugJson getter jsonVal of
                Ok s ->
                    update
                        (RequestDate <| AddServerMsg ("Json value: " ++ s))
                        model

                Err s ->
                    update
                        (RequestDate <| AddServerError ("Debug json error: " ++ s))
                        model

        Default ->
            model ! []

        _ ->
            model ! []


subscriptions model =
    Sub.batch
        [ resizes Resizes
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , downs KeyDown
        ]
