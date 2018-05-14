module Hexaboard.ScoresView exposing (..)

import Char exposing (..)
import Color exposing (..)
import Date exposing (..)
import Dict exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Hexaboard.HexaboardTypes exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr exposing (id)
import Phoenix.Channel exposing (State(..))


scoresView model =
    let
        playerView ( player, id, score ) =
            row [ spacing 15 ]
                [ el
                    [ padding 5

                    --, Border.rounded 5
                    , Background.color (playerColorRgb id)
                    , width <| fillPortion 4
                    , Font.center
                    , Border.rounded 3
                    , Font.family
                        [ Font.typeface "monospace" ]
                    ]
                    (text <| player)
                , el
                    [ padding 5
                    , Background.color Color.lightGrey
                    , width <| fillPortion 1
                    , Font.center
                    , Border.rounded 3
                    ]
                    (text <| toString score)
                ]
    in
    case model.scores of
        [] ->
            none

        scores ->
            column
                [ width (px 200)
                , centerX
                , height shrink
                , spacing 5

                --, Border.solid
                --, Border.width 2
                , padding 2
                ]
                (List.map playerView scores)


capitalize s =
    String.toList s
        |> List.map Char.toUpper
        |> String.fromList


playerColorRgb : Int -> Color
playerColorRgb playerId =
    --color <| 0.7 * toFloat playerId
    if playerId == 1 then
        Color.rgba 255 0 0 0.7
    else if playerId == 2 then
        Color.rgba 255 127 0 0.7
    else if playerId == 3 then
        Color.rgba 255 255 0 0.7
    else if playerId == 4 then
        Color.rgba 0 255 0 0.7
    else if playerId == 5 then
        Color.rgba 0 0 255 0.7
    else if playerId == 6 then
        Color.rgba 180 0 255 0.7
    else
        Color.white
