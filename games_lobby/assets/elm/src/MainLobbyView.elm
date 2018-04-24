module MainLobbyView exposing (..)

import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes as Attr exposing (id)
import MainLobbyTypes exposing (..)
import Phoenix.Channel exposing (State(..))


view : Model -> Html Msg
view model =
    Element.layout
        [ padding 15 ]
    <|
        column [ spacing 15 ]
            [ row
                [ spacing 20 ]
                [ column [ spacing 10 ]
                    [ chatLogView model
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
                            , Border.rounded 5
                            , alignBottom
                            ]
                            { onPress = Just (RequestDate SendChatMessage)
                            , label = text "Send"
                            }
                        ]
                    ]
                , column [ spacing 10 ]
                    [ presencesView model
                    , channelStatusView model "lobby:chat"
                    ]
                ]
            , debugView model
            ]


presencesView model =
    let
        playerView player =
            el
                [ padding 5
                , Border.rounded 5
                , Background.color Color.grey
                ]
                (text player)

        players =
            Dict.keys model.presences
    in
    column [ spacing 15 ]
        [ text "players online:"
        , paragraph [ spacing 5 ] (List.map playerView players)
        ]


prettyDate timeStamp =
    let
        day =
            Date.day timeStamp

        month =
            Date.month timeStamp

        year =
            Date.year timeStamp

        hour =
            Date.hour timeStamp

        minute =
            Date.minute timeStamp
    in
    String.padLeft 2 '0' (toString hour)
        ++ ":"
        ++ String.padLeft 2 '0' (toString minute)


chatLogView model =
    let
        messageView { timeStamp, author, message } =
            column
                [ spacing 3
                , height shrink
                ]
                [ row [ spacing 5 ]
                    [ el
                        [ Font.bold
                        , Font.size 15
                        , centerY
                        ]
                        (text author.username)
                    , el
                        [ alignRight
                        , Font.size 15
                        , Font.color Color.grey
                        , centerY
                        ]
                        (text <| prettyDate timeStamp)
                    ]
                , paragraph
                    [ Font.family
                        [ Font.typeface "monospace" ]
                    , Font.size 15
                    ]
                    [ text message ]
                ]
    in
    column
        [ spacing 10
        , padding 10
        , Border.solid
        , Border.rounded 5
        , Border.width 2
        , Border.color Color.lightGrey
        , width (px 400)
        , height (px 300)
        , scrollbarY
        , htmlAttribute (Attr.id "chatLogContainer")
        ]
        (List.map messageView model.chatLog |> List.reverse)


debugView model =
    column []
        [ paragraph [] [ text <| "log: " ++ model.log ]
        , paragraph [] [ text <| "errors: " ++ model.errors ]
        , paragraph [] [ text <| toString model.gamesMeta ]
        , paragraph [] [ text <| "presences: " ++ toString model.presences ]
        , paragraph [] [ text <| "gamesSetup: " ++ toString model.gamesSetup ]
        ]


channelStatusView model topic =
    case Dict.get topic model.phxSocket.channels of
        Nothing ->
            el [] (text "no channel corresponding to that topic")

        Just channel ->
            let
                controlButton =
                    case channel.state of
                        Joined ->
                            Input.button
                                [ Background.color Color.lightRed
                                , padding 10
                                , Border.rounded 5
                                ]
                                { onPress = Just <| LeaveChannel topic
                                , label = text "Leave channel!"
                                }

                        _ ->
                            Input.button
                                [ Background.color Color.lightBlue
                                , padding 10
                                , Border.rounded 5
                                ]
                                { onPress = Just <| JoinChannel topic
                                , label = text "Join channel!"
                                }
            in
            column
                [ spacing 15 ]
                [ text <| "Channel status: " ++ toString channel.state
                , controlButton
                ]
