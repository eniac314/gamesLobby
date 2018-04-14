module Main exposing (..)

import Color exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html, programWithFlags)
import Json.Decode as Decode
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    }


type alias Model =
    { authToken : String
    , wsUrl : String
    , authSalt : String
    , phxSocket : Phoenix.Socket.Socket Msg
    , log : String
    , errors : String
    }


type Msg
    = Default
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ServerMsg Decode.Value
    | JoinChannel
    | ServerError Decode.Value


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
    { authToken = flags.authToken
    , authSalt = flags.authSalt
    , wsUrl = flags.wsUrl
    , phxSocket = initialSocket flags
    , log = ""
    , errors = ""
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

        --++ "?salt="
        --++ flags.authSalt
    in
    Phoenix.Socket.init wsUrlWithAuth
        |> Phoenix.Socket.on "greetings" "lobby:chat" ServerMsg


view : Model -> Html Msg
view model =
    Element.layout
        []
    <|
        column []
            [ el
                []
                (text "Hello stylish friend!")
            , debugView model
            , Input.button []
                { onPress = Just JoinChannel
                , label = text "Join channel"
                }
            ]


debugView model =
    column []
        [ paragraph [] [ text <| model.authToken ]
        , paragraph [] [ text <| model.authSalt ]
        , paragraph [] [ text <| model.wsUrl ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ServerMsg jsonVal ->
            case Decode.decodeValue (Decode.field "content" Decode.string) jsonVal of
                Ok s ->
                    { model | log = s } ! []

                Err s ->
                    { model | errors = s } ! []

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

        ServerError jsonVal ->
            model ! []

        Default ->
            model ! []


subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg
