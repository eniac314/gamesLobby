module Hexaboard.WinLoseView exposing (..)

import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Hexaboard.Data exposing (shifumiTable)
import Hexaboard.HexaboardTypes exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr exposing (id)
import Phoenix.Channel exposing (State(..))


winLoseView : Model -> Element Msg
winLoseView model =
    case model.choice of
        Just { value, playerId } ->
            let
                ( losers, winners ) =
                    Dict.foldr
                        (\( v1, v2 ) res ( lAcc, wAcc ) ->
                            if v1 /= value || v1 == v2 then
                                ( lAcc, wAcc )
                            else if res > 0 then
                                ( lAcc, ( v2, res ) :: wAcc )
                            else
                                ( ( v2, res ) :: lAcc, wAcc )
                        )
                        ( [], [] )
                        shifumiTable

                makeCell ( v, res ) =
                    let
                        color =
                            if res == 1 then
                                Color.blue
                            else if res == 2 then
                                Color.green
                            else if res == -1 then
                                Color.darkYellow
                            else if res == -2 then
                                Color.darkOrange
                            else
                                Color.white
                    in
                        el
                            [ Background.color color
                            , width (fillPortion 1)
                            , height (fillPortion 1)
                            ]
                            (el
                                [ Background.uncropped <|
                                    "/images/hexaboard/pieces/piece"
                                        ++ toString v
                                        ++ ".png"
                                  --, Background.uncropped
                                , width fill
                                , height (px 55)
                                ]
                                none
                            )

                losersCells =
                    List.map makeCell losers

                winnersCells =
                    List.map makeCell winners
            in
                column
                    [ spacing 3
                    , if model.device.tablet then
                        width (maximum 350 fill)
                      else if model.device.desktop then
                        width (maximum 450 fill)
                      else
                        width (maximum 600 fill)
                    , Border.solid
                    , Border.width 2
                    , padding 5
                    , height shrink
                    , alignTop
                      --, Font.family
                      --    [ Font.typeface "monospace" ]
                      --, Font.size 15
                    ]
                    (if model.displayHints then
                        [ row [ spacing 3 ]
                            (el [ width (minimum 110 (fillPortion 2)) ]
                                (text "loses to: ")
                                :: losersCells
                            )
                        , row [ spacing 3 ]
                            (el [ width (minimum 110 (fillPortion 2)) ]
                                (text "wins against: ")
                                :: winnersCells
                            )
                        , Input.button
                            [ Background.color Color.lightBlue
                            , padding 10
                            , Border.rounded 5
                            , alignBottom
                            , mouseOver [ Font.glow Color.lightBlue 7 ]
                            ]
                            { onPress = Just (HideHints)
                            , label = text "Hide hints"
                            }
                        ]
                     else
                        [ Input.button
                            [ Background.color Color.lightBlue
                            , padding 10
                            , Border.rounded 5
                            , alignBottom
                            , mouseOver [ Font.glow Color.lightBlue 7 ]
                            ]
                            { onPress = Just (ShowHints)
                            , label = text "Show hints"
                            }
                        ]
                    )

        Nothing ->
            none
