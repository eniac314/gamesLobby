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
    , canChooseTurn = False
    , choosenTurn = Nothing
    , availableTurns = []
    , playingOrder = []
    , scores = []
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
        |> Phoenix.Socket.on "piece_picked_up" gameChannel PiecePickedUp
        |> Phoenix.Socket.on "pieces_all_set" gameChannel PiecesAllSet
        |> Phoenix.Socket.on "turn_selected" gameChannel TurnSelected
        |> Phoenix.Socket.on "turns_all_set" gameChannel TurnsAllSet
        |> Phoenix.Socket.on "piece_down" gameChannel PieceDown
        |> Phoenix.Socket.on "round_over" gameChannel RoundOver
        |> Phoenix.Socket.on "game_over" gameChannel GameOver
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
                    update
                        (RequestDate <| AddServerError ("receive presence_state: " ++ e))
                        model

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
                    update
                        (RequestDate <| AddServerError ("receive presence_diff: " ++ e))
                        model

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

                        ( newModel, phxCmd ) =
                            pushGameMsg model "requesting_gamestate" Nothing Nothing
                    in
                    { newModel | playerInfo = newPlInf }
                        ! [ Cmd.map PhoenixMsg phxCmd ]

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
                Ok { board, deck, id, availableTurns, turnSelectionOrder, playingOrder, piece, gameOver, scores } ->
                    let
                        plInf =
                            model.playerInfo

                        choice =
                            Maybe.map
                                (\v ->
                                    { playerId = id
                                    , value = v
                                    }
                                )
                                piece

                        canChooseTurn =
                            List.head turnSelectionOrder
                                |> Maybe.map (\pid -> pid == id)
                                |> Maybe.withDefault False

                        canPlay =
                            List.head playingOrder
                                |> Maybe.map (\pid -> pid == id)
                                |> Maybe.withDefault False

                        gameState =
                            if gameOver then
                                EndGame
                            else if turnSelectionOrder == [] && playingOrder == [] && choice == Nothing then
                                PieceSelection
                            else if turnSelectionOrder == [] && playingOrder == [] then
                                WaitingForEndOfPieceSelection
                            else if availableTurns /= [] then
                                TurnSelection
                            else if not canPlay && playingOrder /= [] && choice /= Nothing then
                                WaitingForOwnTurn
                            else if canPlay && playingOrder /= [] then
                                Playing
                            else if playingOrder /= [] && choice == Nothing then
                                WaitingForEndOfRound
                            else
                                EndGame

                        newModel =
                            { model
                                | board = board
                                , deck = deck
                                , choice = choice
                                , availableTurns = availableTurns
                                , playingOrder = playingOrder
                                , playerInfo = { plInf | playerId = id }
                                , canChooseTurn = canChooseTurn
                                , gameState = gameState
                                , scores = scores
                            }
                    in
                    update
                        (RequestDate <| AddGameMsg "initial game state loaded")
                        newModel

                Err e ->
                    update
                        (RequestDate <| AddServerError ("update game state - json error: " ++ e))
                        model

        PickUpPiece ({ value, playerId } as piece) ->
            case model.gameState of
                PieceSelection ->
                    let
                        payload =
                            Just <| encodePickedUpPiece piece

                        ( newModel, phxCmd ) =
                            pushGameMsg
                                model
                                "set_player_piece"
                                payload
                                Nothing
                    in
                    newModel ! [ Cmd.map PhoenixMsg phxCmd ]

                _ ->
                    model ! []

        PiecePickedUp jsonVal ->
            case decodePlayer model.playerInfo.username jsonVal of
                Ok ( d, id, p ) ->
                    { model
                        | gameState =
                            if model.gameState == PieceSelection then
                                WaitingForEndOfPieceSelection
                            else
                                model.gameState
                        , deck = List.map (\v -> { value = v, playerId = id }) d
                        , choice = Maybe.map (\v -> { value = v, playerId = id }) p
                    }
                        ! []

                Err e ->
                    update
                        (RequestDate <| AddServerError ("pieces all set - json error: " ++ e))
                        model

        PiecesAllSet jsonVal ->
            case decodeTurnsInfo jsonVal of
                Ok { availableTurns, turnSelectionOrder } ->
                    { model
                        | gameState = TurnSelection
                        , availableTurns = availableTurns
                        , canChooseTurn =
                            List.head turnSelectionOrder
                                |> Maybe.map (\id -> id == model.playerInfo.playerId)
                                |> Maybe.withDefault False
                    }
                        ! []

                Err e ->
                    update
                        (RequestDate <| AddServerError ("pieces all set - json error: " ++ e))
                        model

        SelectTurn turn ->
            let
                payload =
                    Just <| Encode.object [ ( "turn", Encode.int turn ) ]

                ( newModel, phxCmd ) =
                    pushGameMsg
                        model
                        "turn_selected"
                        payload
                        Nothing
            in
            { newModel | choosenTurn = Nothing }
                ! [ Cmd.map PhoenixMsg phxCmd ]

        TurnSelected jsonVal ->
            case decodeTurnsInfo jsonVal of
                Ok { availableTurns, turnSelectionOrder } ->
                    { model
                        | gameState = TurnSelection
                        , availableTurns = availableTurns
                        , canChooseTurn =
                            List.head turnSelectionOrder
                                |> Maybe.map (\id -> id == model.playerInfo.playerId)
                                |> Maybe.withDefault False
                    }
                        ! []

                Err e ->
                    update
                        (RequestDate <| AddServerError ("turn selected - json error: " ++ e))
                        model

        TurnsAllSet jsonVal ->
            case decodeTurnsInfo jsonVal of
                Ok { playingOrder } ->
                    let
                        canPlay =
                            List.head playingOrder
                                |> Maybe.map (\id -> id == model.playerInfo.playerId)
                                |> Maybe.withDefault False
                    in
                    { model
                        | gameState =
                            if canPlay then
                                Playing
                            else
                                WaitingForOwnTurn
                        , availableTurns = []
                        , playingOrder = playingOrder
                        , canChooseTurn = False
                    }
                        ! []

                Err e ->
                    update
                        (RequestDate <| AddServerError ("turns all set - json error: " ++ e))
                        model

        PutDownPiece ( x, y ) ->
            case model.gameState of
                Playing ->
                    let
                        payload =
                            Just <|
                                Encode.object
                                    [ ( "player_id", Encode.int model.playerInfo.playerId )
                                    , ( "pos_x", Encode.int x )
                                    , ( "pos_y", Encode.int y )
                                    ]

                        ( newModel, phxCmd ) =
                            pushGameMsg
                                model
                                "put_down_piece"
                                payload
                                Nothing
                    in
                    { newModel
                        | choice = Nothing
                        , gameState = WaitingForEndOfRound
                    }
                        ! [ Cmd.map PhoenixMsg phxCmd ]

                _ ->
                    model ! []

        PieceDown jsonVal ->
            case decodePieceDown model.playerInfo.username jsonVal of
                Ok { board, playingOrder, scores } ->
                    let
                        canPlay =
                            List.head playingOrder
                                |> Maybe.map (\id -> id == model.playerInfo.playerId)
                                |> Maybe.withDefault False
                    in
                    { model
                        | board = board
                        , playingOrder = playingOrder
                        , scores = scores
                        , gameState =
                            if canPlay then
                                Playing
                            else
                                WaitingForEndOfRound
                    }
                        ! []

                Err e ->
                    update
                        (RequestDate <| AddServerError ("piece down - json error: " ++ e))
                        model

        RoundOver _ ->
            { model
                | gameState = PieceSelection
                , choice = Nothing
                , canChooseTurn = False
                , choosenTurn = Nothing
                , availableTurns = []
                , playingOrder = []
            }
                ! []

        GameOver _ ->
            { model | gameState = EndGame } ! []

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

        ServerMsg jsonVal ->
            case Decode.decodeValue Decode.string jsonVal of
                Ok msg ->
                    update
                        (RequestDate <| AddServerMsg ("ServerMsg: " ++ msg))
                        model

                Err e ->
                    update
                        (RequestDate <| AddServerError ("ServerMsg: json decoding error: " ++ e))
                        model

        ServerError jsonVal ->
            case Decode.decodeValue Decode.string jsonVal of
                Ok e ->
                    update
                        (RequestDate <| AddServerError ("ServerError: " ++ e))
                        model

                Err e ->
                    update
                        (RequestDate <| AddServerError ("ServerErr: json decoding error: " ++ e))
                        model

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

        DropRes _ ->
            model ! []

        DropJson _ ->
            model ! []

        Default ->
            model ! []


subscriptions model =
    Sub.batch
        [ resizes Resizes
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , downs KeyDown
        ]


pushGameMsg model topic mbPayload mbOkHandler =
    let
        payload =
            Maybe.withDefault (Encode.object []) mbPayload

        okHandler =
            Maybe.withDefault DropJson mbOkHandler

        msg =
            Phoenix.Push.init topic ("hexaboard:game:" ++ model.gameId)
                |> Phoenix.Push.withPayload payload
                |> Phoenix.Push.onError ServerError
                |> Phoenix.Push.onOk okHandler

        ( newSocket, phxCmd ) =
            Phoenix.Socket.push msg model.phxSocket
    in
    ( { model | phxSocket = newSocket }, phxCmd )
