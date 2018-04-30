module Hexaboard exposing (..)

import AnimationFrame exposing (diffs)
import Date exposing (..)
import Dict exposing (..)
import Dom.Scroll as Scroll
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
import Time exposing (Time, every, second)


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
        hexaboardChat =
            initPhoenixChannel "hexaboard:chat"

        hexaboardGame =
            initPhoenixChannel "hexaboard:game"

        ( newSocket1, phxCmd1 ) =
            Phoenix.Socket.join hexaboardChat (initialSocket flags)

        ( newSocket2, phxCmd2 ) =
            Phoenix.Socket.join hexaboardGame newSocket1

        phxCmd =
            Cmd.batch [ phxCmd1, phxCmd2 ]
    in
    { wsUrl = flags.wsUrl
    , authToken = flags.authToken
    , authSalt = flags.authSalt
    , phxSocket = newSocket2
    , playerInfo = defPlayer
    , presences = Dict.empty
    , chatMessageInput = ""
    , chatLog = []
    , chatMessageBoxFocused = False
    , board = Dict.empty
    , gameState = PieceSelection
    }
        ! [ Cmd.map PhoenixMsg phxCmd ]


initPhoenixChannel : String -> Phoenix.Channel.Channel Msg
initPhoenixChannel topic =
    Phoenix.Channel.init topic


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
        |> Phoenix.Socket.on "greetings" "hexaboard:chat" ReceivePlayerInfo
        |> Phoenix.Socket.on "presence_state" "hexaboard:chat" ReceivePresenceState
        |> Phoenix.Socket.on "presence_diff" "hexaboard:chat" ReceivePresenceDiff
        |> Phoenix.Socket.on "new_chat_message" "hexaboard:chat" ReceiveChatMessage
        |> Phoenix.Socket.on "chat_history" "hexaboard:chat" UpdateChatLog
        |> Phoenix.Socket.withDebug


update msg model =
    model ! []


subscriptions model =
    Sub.none
