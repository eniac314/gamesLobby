module Hexaboard.ScoresView exposing (scoresView)

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
import Svg exposing (..)
import Svg.Attributes as SvgAttr
import Svg.Events as SvgEvents


scoresView model =
    let
        canPlay id =
            List.head model.playingOrder
                |> Maybe.map (\fid -> fid == id)
                |> Maybe.withDefault False

        playerView { username, playerId, score, piece } =
            row [ spacing 15 ]
                [ el
                    [ padding 5
                      --, Border.rounded 5
                    , Background.color (playerColorRgb playerId)
                    , width <| fillPortion 4
                    , Font.center
                    , if canPlay playerId then
                        Font.bold
                      else
                        Font.unitalicized
                    , Border.rounded 3
                    , Font.family
                        [ Font.typeface "monospace" ]
                    ]
                    (Element.text <| username)
                , el
                    [ padding 5
                    , Background.color Color.lightGrey
                    , width <| fillPortion 1
                    , Font.center
                    , Border.rounded 3
                    ]
                    (Element.text <| toString score)
                  --, text <| toString id
                  --, text <| toString model.playingOrder
                , if model.gameState == TurnSelection then
                    selectedSvg piece
                  else
                    selectedSvg Nothing
                ]
    in
        case model.players of
            [] ->
                none

            players ->
                column
                    [ width (px 200)
                    , centerX
                    , height shrink
                    , spacing 5
                    , padding 2
                    ]
                    (List.map playerView players)


selectedSvg piece =
    let
        box =
            el
                [ width (px 50)
                , height (px 50)
                , centerX
                ]
    in
        case piece of
            Nothing ->
                box none

            Just piece ->
                box <|
                    (html <|
                        svg
                            [ SvgAttr.viewBox <| "0 0 100 100"
                            , SvgAttr.width "100%"
                            , SvgAttr.height "100%"
                            ]
                            (selectedHexaSvg 35 piece)
                    )


selectedHexaSvg radius { value, playerId } =
    let
        points =
            [ ( radius, 0 )
            , ( radius, pi / 3 )
            , ( radius, 2 * pi / 3 )
            , ( radius, pi )
            , ( radius, 4 * pi / 3 )
            , ( radius, 5 * pi / 3 )
            ]
                |> List.map (\( l, a ) -> ( l, a + pi / 6 ))
                |> List.map fromPolar
                |> List.map (\( u, v ) -> ( u + 50, v + 50 ))
                |> List.foldr (\( u, v ) acc -> acc ++ (toString u ++ ", " ++ toString v ++ " ")) ""
    in
        [ polygon
            [ SvgAttr.fill <| playerColor playerId
            , SvgAttr.points points
            ]
            []
        , polygon
            [ SvgAttr.fill <| "url(#piece" ++ toString value ++ ")"
            , SvgAttr.stroke "black"
            , SvgAttr.strokeWidth "2px"
            , SvgAttr.points points
            ]
            []
        ]


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


playerColor : Int -> String
playerColor playerId =
    if playerId == 1 then
        "#ff0000"
    else if playerId == 2 then
        "#ff7f00"
    else if playerId == 3 then
        "#ffff00"
    else if playerId == 4 then
        "#00ff00"
    else if playerId == 5 then
        "#0000ff"
    else if playerId == 6 then
        "#b400ff"
    else
        "white"


piecesPatterns =
    --https://stackoverflow.com/questions/29442833/svg-image-inside-circle
    List.map
        (\n ->
            pattern
                [ SvgAttr.id ("piece" ++ toString n)
                , SvgAttr.x "0%"
                , SvgAttr.y "0%"
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 100 100"
                ]
                [ Svg.image
                    [ SvgAttr.x "10"
                    , SvgAttr.y "10"
                    , SvgAttr.height "80"
                    , SvgAttr.width "80"
                    , SvgAttr.xlinkHref <|
                        "images/hexaboard/pieces/piece"
                            ++ toString n
                            ++ ".png"
                    ]
                    []
                ]
        )
        (List.range 0 14)
