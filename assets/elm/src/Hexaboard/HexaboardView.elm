module Hexaboard.HexaboardView exposing (..)

import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Hexaboard.BoardView exposing (..)
import Hexaboard.DeckView exposing (..)
import Hexaboard.HexaboardTypes exposing (..)
import Hexaboard.ScoresView exposing (..)
import Hexaboard.TurnSelectionView exposing (..)
import Hexaboard.WinLoseView exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr exposing (attribute, id)
import Phoenix.Channel exposing (State(..))


view model =
    Element.layout
        [ padding 15
        , Font.size 18

        --, Background.color Color.blue
        , height (px <| model.winSize.height)
        , Background.tiled "/images/hexaboard/tiles/ep_naturalwhite.png"
        ]
    <|
        row
            [ spacing 20

            --, Background.color Color.green
            , height fill
            ]
            [ consoleView model
            , column
                [ spacing 10

                --, Background.color Color.green
                , if model.device.tablet then
                    width (maximum 350 fill)
                  else if model.device.desktop then
                    width (maximum 450 fill)
                  else
                    width (maximum 600 fill)
                ]
                [ el
                    [ --Background.color Color.red
                      --if model.device.tablet then
                      --  width (maximum 350 fill)
                      --else if model.device.desktop then
                      --  width (maximum 450 fill)
                      --else
                      --  width (maximum 600 fill)
                      width fill
                    , centerX
                    , alignTop
                    ]
                    (hexaBoardSvg 6 35 model.board)
                , viewSelection model
                ]
            , column
                [ spacing 70

                --, Background.color Color.red
                ]
                [ el
                    [ Region.heading 1
                    , paddingEach
                        { bottom = 0
                        , left = 0
                        , right = 0
                        , top = 30
                        }
                    , centerX
                    , if model.device.tablet then
                        Font.size 36
                      else if model.device.desktop then
                        Font.size 48
                      else
                        Font.size 60
                    , Font.family
                        [ Font.external
                            { name = "Anurati"
                            , url = "/css/fonts.css"
                            }
                        , Font.typeface "Anurati"
                        ]
                    ]
                    (text "HEXABOARD")
                , selectedSvg model
                , scoresView model

                --, el [] (text <| toString model.gameState)
                --, el [] (text <| toString model.playingOrder)
                --, el [] (text <| toString model.availableTurns)
                --, el [] (text <| toString model.scores)
                --, paragraph [] [ text <| toString model ]
                ]
            ]


viewSelection model =
    case model.gameState of
        PieceSelection ->
            el
                [ width fill
                , alignTop
                , alignRight

                --, Background.color Color.red
                ]
                (deckSvg model)

        WaitingForEndOfPieceSelection ->
            el
                [ width fill
                , alignTop
                , alignRight

                --, Background.color Color.red
                ]
                (deckSvg model)

        TurnSelection ->
            turnSelectionView model

        WaitingForOwnTurn ->
            winLoseView model

        Playing ->
            winLoseView model

        WaitingForEndOfRound ->
            winLoseView model

        EndGame ->
            endGameView model


consoleView model =
    column
        [ spacing 10
        , height (px <| model.winSize.height - 60)
        , width (maximum 350 fill)
        , alignLeft
        , alignTop
        ]
        [ consoleLogView model
        , row [ spacing 10 ]
            [ Input.text
                [ width fill
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


consoleLogView model =
    let
        messageView msg =
            case msg of
                ChatMsg msg ->
                    chatMsgView msg

                ServerComMsg msg ->
                    serverComMsgView msg

                ServerErrorMsg msg ->
                    serverErrorMsgView msg

                GameMsg msg ->
                    gameMsgView msg
    in
    column
        [ spacing 10
        , padding 10
        , Border.solid
        , Border.rounded 5
        , Border.width 2
        , Border.color Color.lightGrey
        , width fill
        , scrollbarY
        , htmlAttribute (Attr.id "chatLogContainer")
        , Background.color Color.white
        ]
        (List.map messageView model.consoleLog |> List.reverse)


chatMsgView { timeStamp, author, message } =
    column
        [ spacing 3
        , height shrink
        , width fill
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


serverComMsgView { timeStamp, message } =
    column
        [ spacing 3
        , height shrink
        , width fill
        ]
        [ row [ spacing 5 ]
            [ el
                [ Font.bold
                , Font.size 15
                , centerY
                , Font.color Color.purple
                ]
                (text "server com")
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

            --, htmlAttribute (Attr.attribute "pre" "true")
            ]
            [ text message ]
        ]


serverErrorMsgView { timeStamp, message } =
    column
        [ spacing 3
        , height shrink
        , width fill
        ]
        [ row [ spacing 5 ]
            [ el
                [ Font.bold
                , Font.size 15
                , centerY
                , Font.color Color.red
                ]
                (text "server error")
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


gameMsgView { timeStamp, message } =
    column
        [ spacing 3
        , height shrink
        , width fill
        ]
        [ row [ spacing 5 ]
            [ el
                [ Font.bold
                , Font.size 15
                , centerY
                , Font.color Color.blue
                ]
                (text "game message")
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

            --, htmlAttribute (Attr.attribute "pre" "true")
            ]
            [ text message ]
        ]


endGameView { scores } =
    let
        winner =
            List.sortBy (\( a, b, c ) -> c) scores
                |> List.reverse
                |> List.map (\( a, _, _ ) -> a)
                |> List.head
                |> Maybe.withDefault ""
    in
    column
        [ spacing 20 ]
        [ el
            [ Font.size 25
            , centerX
            ]
            (text "Game Over")
        , el [ centerX ]
            (text <| "The winner is " ++ winner)
        ]



--presencesView model =
--    let
--        playerView player =
--            el
--                [ padding 5
--                , Border.rounded 5
--                , Background.color Color.grey
--                ]
--                (text player)
--        players =
--            Dict.keys model.presences
--    in
--    column
--        [ spacing 15
--        , width shrink
--        ]
--        [ text "players online:"
--        , paragraph [ spacing 5 ] (List.map playerView players)
--        ]


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
