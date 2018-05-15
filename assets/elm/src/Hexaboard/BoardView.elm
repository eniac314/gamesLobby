module Hexaboard.BoardView exposing (..)

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


hexaBoardSvg n l board =
    let
        coords =
            board
                |> Dict.values
                |> List.map (\{ xPos, yPos, state } -> ( xPos, yPos, state ))
                |> List.map (\( u, v, state ) -> ( toFloat u, toFloat v, state ))

        adjust v =
            if round v % 2 == 0 then
                0
            else
                0

        offset v =
            if v >= toFloat n + 1 then
                v - n
            else
                n - v

        yOffset x y =
            fromPolar ( l, pi / 3 )
                |> (\( x, y ) -> l - y)

        cells =
            List.concatMap
                (\( u, v, state ) ->
                    hexaSvg
                        (l + u * l * 2 + offset v * l)
                        (v * 2 * l + 2 * l - v * 2 * yOffset u v)
                        state
                        l
                        u
                        v
                )
                coords

        size =
            toString (l * 4 * n + 2 * l)

        def =
            defs []
                piecesPatterns
    in
    html <|
        svg
            [ SvgAttr.width "100%"
            , SvgAttr.height "100%"
            , SvgAttr.viewBox <| "0 0 " ++ size ++ " " ++ size
            ]
            (def :: cells)



--, br [] []
--, Html.text <| "number of cells: " ++ (toString <| List.length cells)


hexaSvg : Float -> Float -> CellState -> Float -> Float -> Float -> List (Svg Msg)
hexaSvg x y state l u v =
    let
        offset =
            fromPolar ( l, pi / 3 )
                |> (\( x, y ) -> l - y)

        radius =
            l + offset

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
                |> List.map (\( u, v ) -> ( u + x, v + y ))
                |> List.foldr (\( u, v ) acc -> acc ++ (toString u ++ ", " ++ toString v ++ " ")) ""
    in
    (case state of
        Contain { value, playerId } ->
            [ polygon
                [ SvgAttr.fill <| playerColor playerId
                , SvgAttr.points points
                ]
                []
            ]

        _ ->
            []
    )
        ++ [ polygon
                [ case state of
                    Empty ->
                        SvgAttr.fill "white"

                    UnPlayable Grey ->
                        SvgAttr.fill "grey"

                    UnPlayable (Rainbow c) ->
                        SvgAttr.fill c

                    Contain { value, playerId } ->
                        SvgAttr.fill <| "url(#piece" ++ toString value ++ ")"
                , SvgAttr.stroke "black"
                , SvgAttr.strokeWidth "2px"
                , SvgAttr.points points
                , case state of
                    Empty ->
                        SvgEvents.onClick (PutDownPiece ( round u, round v ))

                    _ ->
                        SvgEvents.onClick Default
                , case state of
                    Empty ->
                        SvgAttr.cursor "pointer"

                    _ ->
                        SvgAttr.cursor "default"
                ]
                []

           --, text_
           --     [ SvgAttr.x (toString <| x - l / 1.5)
           --     , SvgAttr.y (toString <| y)
           --     , SvgAttr.stroke "black"
           --     ]
           --     [ Svg.text ("(" ++ toString u ++ ", " ++ toString v ++ ")") ]
           ]


playerColor : Int -> String
playerColor playerId =
    --color <| 0.7 * toFloat playerId
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
