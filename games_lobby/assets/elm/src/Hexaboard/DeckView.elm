module Hexaboard.DeckView exposing (..)

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


deckSvg { deck, playerInfo, device } =
    let
        id =
            playerInfo.playerId

        -- l is the length of half an hexagone
        l =
            35

        offset =
            5

        ( sizeX, sizeY, i, j ) =
            let
                i =
                    if device.tablet then
                        5
                    else
                        3

                j =
                    if device.tablet then
                        3
                    else
                        5
            in
            ( offset * (j - 1) + 2 * l * j
            , offset * (i - 1) + 2 * l * i
            , i
            , j
            )

        coords rowIndex acc =
            case rowIndex of
                0 ->
                    List.map
                        (\( x, y ) ->
                            ( l + x * (l + l + offset)
                            , l + y * (l + l + offset)
                            )
                        )
                        acc

                y ->
                    let
                        newRow =
                            List.map (\x -> ( toFloat x, i - y )) (List.range 0 (j - 1))
                    in
                    coords (y - 1) (acc ++ newRow)

        isInDeck ( i, _ ) =
            List.any (\p -> p.value == i) deck

        deckCoords =
            coords i []
                |> List.indexedMap (,)
                |> List.filter isInDeck
                |> List.map Tuple.second

        pieces =
            List.map2 (,) deckCoords deck
                |> List.concatMap (\( ( x, y ), piece ) -> deckHexaSvg x y l piece)

        def =
            defs []
                piecesPatterns
    in
    el
        [ centerX
        , alignTop
        , if device.tablet then
            width (px 200)
          else if device.desktop then
            width (px 400)
          else
            width (px 350)

        --, Background.color Color.blue
        ]
        (html <|
            svg
                [ SvgAttr.viewBox <| "0 0 " ++ toString sizeX ++ " " ++ toString sizeY
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                ]
                (def
                    :: pieces
                )
        )


deckHexaSvg x y radius { value, playerId } =
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
                |> List.map (\( u, v ) -> ( u + x, v + y ))
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
        , SvgEvents.onClick (PickUpPiece (Piece value playerId))
        , SvgAttr.cursor "pointer"
        ]
        []
    ]


selectedSvg model =
    let
        box =
            el
                [ Border.solid
                , Border.width 2
                , width (px 100)
                , height (px 100)

                --, Background.color Color.blue
                ]
    in
    case model.choice of
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
