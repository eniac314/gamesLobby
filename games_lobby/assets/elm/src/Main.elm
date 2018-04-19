module Main exposing (..)

import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
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
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket
import Task exposing (..)


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    }


type alias Model =
    { wsUrl : String
    , authToken : String
    , authSalt : String
    , phxSocket : Phoenix.Socket.Socket Msg
    , playerInfo : Player
    , log : String
    , errors : String
    , presences : Presence.PresenceState Player
    , chatMessageInput : String
    , chatLog : List ChatMessage
    , chatMessageBoxFocused : Bool
    }


type alias ChatMessage =
    { timeStamp : Date
    , author : Player
    , message : String
    }


type alias Player =
    { onlineAt : String
    , username : String
    }


defPlayer =
    Player "" ""


type Msg
    = Default
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | ReceivePlayerInfo Decode.Value
    | ReceivePresenceState Decode.Value
    | ReceivePresenceDiff Decode.Value
    | ServerMsg Decode.Value
    | ServerError Decode.Value
    | ChatMessageInput String
    | SendChatMessage Date
    | ReceiveChatMessage Decode.Value
    | FocusChatMessageBox
    | UnfocusChatMessageBox
    | KeyDown KeyCode
    | RequestDate (Date -> Msg)


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
    { wsUrl = flags.wsUrl
    , authToken = flags.authToken
    , authSalt = flags.authSalt
    , phxSocket = initialSocket flags
    , playerInfo = defPlayer
    , log = ""
    , errors = ""
    , presences = Dict.empty
    , chatMessageInput = ""
    , chatLog = []
    , chatMessageBoxFocused = False
    }
        ! []


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
        |> Phoenix.Socket.withoutHeartbeat
        |> Phoenix.Socket.withDebug


view : Model -> Html Msg
view model =
    Element.layout
        [ padding 15 ]
    <|
        column []
            [ listPlayers model
            , Input.button
                [ Background.color Color.lightBlue
                , padding 10
                ]
                { onPress = Just JoinChannel
                , label = text "Join channel!"
                }
            , row [ spacing 10 ]
                [ Input.text
                    [ width (px 300)
                    , Events.onFocus FocusChatMessageBox
                    , Events.onLoseFocus UnfocusChatMessageBox
                    ]
                    { onChange = Just ChatMessageInput
                    , text = model.chatMessageInput
                    , placeholder = Nothing
                    , label = Input.labelAbove [] (text "message: ")
                    }
                , Input.button
                    [ Background.color Color.lightBlue
                    , padding 10
                    , alignBottom
                    ]
                    { onPress = Just (RequestDate SendChatMessage)
                    , label = text "Send"
                    }
                ]
            , chatLogView model
            ]


listPlayers model =
    let
        playerView n player =
            el
                [ padding 5
                , if n % 2 == 0 then
                    Background.color Color.grey
                  else
                    Background.color Color.white
                ]
                (text player)

        players =
            Dict.keys model.presences
    in
    column [ spacing 15 ] (List.indexedMap playerView players)


chatLogView model =
    let
        messageView { timeStamp, author, message } =
            row [ spacing 20 ]
                [ text author.username
                , text message
                ]
    in
    column [ spacing 10 ] (List.map messageView model.chatLog)


debugView model =
    column []
        [ paragraph [] [ text <| toString model.playerInfo ]
        , paragraph [] [ text <| model.wsUrl ]
        ]


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage { timeStamp, author, message } =
    Encode.object
        [ ( "time_stamp", Encode.float (toTime timeStamp) )
        , ( "author", encodePlayer author )
        , ( "message", Encode.string message )
        ]


decodeChatMessage : Decode.Value -> Result String ChatMessage
decodeChatMessage jsonVal =
    Decode.decodeValue
        (Decode.map3 ChatMessage
            (Decode.field "time_stamp" decodeDate)
            (Decode.field "author" playerDecoder)
            (Decode.field "message" Decode.string)
        )
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
                        |> Result.map (Presence.syncState model.presences)
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

        JoinChannel ->
            let
                channel =
                    initPhoenixChannel "lobby:chat"

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
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
                    { model | chatLog = message :: model.chatLog } ! []

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

        Default ->
            model ! []


subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , downs KeyDown
        ]
