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
        [ padding 15
        , Font.size 18
        ]
    <|
        column
            [ spacing 20 ]
            [ el
                [ Font.size 32
                , Font.bold
                ]
                (text "Game Lobby")
            , row
                [ spacing 15
                , width fill

                --, Background.color Color.green
                ]
                [ chatView model
                , gamesSetupView model
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
                , centerX
                ]
                (text player)

        players =
            Dict.keys model.presences
    in
    column
        [ spacing 15
        , width shrink

        --, Background.color Color.purple
        ]
        [ text "players online:"
        , column [ spacing 10 ] (List.map playerView players)
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


chatView model =
    row
        [ spacing 20

        --, Background.color Color.blue
        , width shrink
        ]
        [ column
            [ spacing 10
            , width shrink
            ]
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
                    , mouseOver [ Font.glow Color.lightBlue 7 ]
                    ]
                    { onPress = Just (RequestDate SendChatMessage)
                    , label = text "Send"
                    }
                ]
            ]
        , presencesView model
        ]


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
                    , width fill
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
                                , mouseOver [ Font.glow Color.lightRed 7 ]
                                ]
                                { onPress = Just <| LeaveChannel topic
                                , label = text "Leave channel!"
                                }

                        _ ->
                            Input.button
                                [ Background.color Color.lightBlue
                                , padding 10
                                , Border.rounded 5
                                , mouseOver [ Font.glow Color.lightBlue 7 ]
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


gameMetaView : GameMeta -> Element Msg
gameMetaView ({ name, minPlayers, maxPlayers, hasIA } as gamesMeta) =
    column
        [ spacing 10
        , padding 10
        , Border.rounded 5
        , Events.onClick (SelectGame gamesMeta)
        , pointer
        , Background.color Color.lightGrey
        , mouseOver [ Background.color Color.grey ]
        , width shrink
        , Font.size 17
        ]
        [ el [ Font.bold ] (text name)
        , el [] (text <| "Min players: " ++ toString minPlayers)
        , el [] (text <| "Max players: " ++ toString maxPlayers)
        , el [] (text <| "Has AI: " ++ toString hasIA)
        ]


gameSetupView : Model -> GameSetup -> Element Msg
gameSetupView model { gameMeta, joined, hasStarted, host, gameId } =
    case host of
        Nothing ->
            Element.none

        Just host ->
            let
                gameTitle =
                    (Tuple.first gameId).name
                        ++ " "
                        ++ (toString <| Tuple.second gameId)

                isGameSetupHost =
                    model.playerInfo.username == host

                hasJoinedGameSetup =
                    List.member model.playerInfo.username joined

                canStart =
                    List.length joined + 1 >= gameMeta.minPlayers

                usrView usr =
                    let
                        usrHasStarted =
                            if List.member usr hasStarted then
                                " Ok"
                            else
                                ""

                        usrStr =
                            usr ++ usrHasStarted
                    in
                    el [] (text usrStr)
            in
            column
                [ spacing 10
                , Font.size 16
                , Background.color Color.lightOrange
                , height (px 200)
                , width shrink
                , padding 10
                , alignTop
                , Border.rounded 5
                ]
                [ el [ Font.bold ] (text gameTitle)
                , el [] (text <| "Game hosted by: " ++ host)
                , column
                    [ spacing 10
                    , scrollbarY
                    ]
                    (List.map usrView joined)
                , if isGameSetupHost then
                    Input.button
                        [ Background.color Color.lightRed
                        , padding 10
                        , Border.rounded 5
                        , mouseOver [ Font.glow Color.lightRed 7 ]
                        ]
                        { onPress = Just <| DeleteGame gameId
                        , label = text "Delete Game"
                        }
                  else if not (hasJoined model) && not (isHost model) then
                    Input.button
                        [ Background.color Color.lightBlue
                        , padding 10
                        , Border.rounded 5
                        , mouseOver [ Font.glow Color.lightBlue 7 ]
                        ]
                        { onPress = Just <| JoinGame gameId
                        , label = text "Join game!"
                        }
                  else if hasJoinedGameSetup then
                    Input.button
                        [ Background.color Color.lightBlue
                        , padding 10
                        , Border.rounded 5
                        , mouseOver [ Font.glow Color.lightBlue 7 ]
                        ]
                        { onPress = Just <| LeaveGame gameId
                        , label = text "Leave game"
                        }
                  else
                    Element.none
                , if canStart && not model.waitingForOthers then
                    Input.button
                        [ Background.color Color.lightGreen
                        , padding 10
                        , Border.rounded 5
                        , mouseOver [ Font.glow Color.lightGreen 7 ]
                        ]
                        { onPress = Just <| StartGame gameId
                        , label = text "Start game"
                        }
                  else if model.waitingForOthers then
                    el [] (text "waiting to start...")
                  else
                    Element.none
                ]


gamesSetupView model =
    case model.currentSelectedGame of
        Nothing ->
            let
                rows =
                    nChunks 3 (Dict.values model.gamesMeta)
                        |> List.map (\r -> row [ spacing 10 ] (List.map gameMetaView r))
            in
            column
                [ spacing 10 ]
                [ text "choose a game:"
                , column
                    [ --Background.color Color.lightGreen
                      spacing 10
                    ]
                    rows
                ]

        Just gameMeta ->
            column
                [ spacing 10 ]
                [ el [ Font.bold ] (text gameMeta.name)
                , row
                    [ spacing 10
                    , height fill
                    ]
                    (List.map (gameSetupView model)
                        (Dict.filter (\k v -> v.gameMeta.name == gameMeta.name) model.gamesSetup
                            |> Dict.values
                        )
                    )
                , row
                    [ spacing 10
                    , alignBottom
                    ]
                    [ if not (hasJoined model) && not (isHost model) then
                        Input.button
                            [ Background.color Color.lightBlue
                            , padding 10
                            , Border.rounded 5
                            , mouseOver [ Font.glow Color.lightBlue 7 ]
                            ]
                            { onPress = Just <| NewGame
                            , label = text "New Game!"
                            }
                      else
                        Element.none
                    , Input.button
                        [ Background.color Color.lightBlue
                        , padding 10
                        , Border.rounded 5
                        , mouseOver [ Font.glow Color.lightBlue 7 ]
                        ]
                        { onPress = Just <| UnSelectGame
                        , label = text "Back to game list"
                        }
                    ]
                ]


isHost model =
    let
        username =
            model.playerInfo.username
    in
    model.gamesSetup
        |> Dict.filter (\k v -> v.host == Just username)
        |> Dict.size
        |> (\s -> s > 0)


hasJoined model =
    let
        username =
            model.playerInfo.username
    in
    model.gamesSetup
        |> Dict.filter (\k v -> List.member username v.joined)
        |> Dict.size
        |> (\s -> s > 0)


nChunks n xs =
    let
        go acc1 acc2 m xs =
            case xs of
                [] ->
                    List.reverse (List.reverse acc2 :: acc1)

                x :: xs ->
                    if m == 1 then
                        go (List.reverse (x :: acc2) :: acc1)
                            []
                            n
                            xs
                    else
                        go acc1 (x :: acc2) (m - 1) xs
    in
    go [] [] n xs
