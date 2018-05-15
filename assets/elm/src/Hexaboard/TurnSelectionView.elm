module Hexaboard.TurnSelectionView exposing (..)

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


turnSelectionView model =
    let
        size =
            List.length model.availableTurns

        chunks =
            if size < 3 then
                nChunks 1 model.availableTurns
            else if size < 5 then
                nChunks 2 model.availableTurns
            else
                nChunks 3 model.availableTurns

        turnView turn =
            el
                ([ Background.color Color.lightBlue
                 , padding 10
                 , Border.rounded 5
                 , width fill
                 , Font.center
                 ]
                    ++ (if model.canChooseTurn then
                            [ mouseOver [ Font.glow Color.lightBlue 7 ]
                            , pointer
                            , Events.onClick (SelectTurn turn)
                            ]
                        else
                            []
                       )
                )
                (text <| toString turn)

        chunkView chunk =
            column
                [ width fill
                , padding 5
                , spacing 10

                --, Background.color Color.green
                ]
                (List.map turnView chunk)
    in
    column
        [ if model.device.tablet then
            width (maximum 350 fill)
          else if model.device.desktop then
            width (maximum 450 fill)
          else
            width (maximum 600 fill)
        , spacing 10
        ]
        [ row [ padding 10 ]
            [ el []
                (Element.text "Turn selection - available turns: ")
            , if model.canChooseTurn then
                el
                    [ alignRight
                    , Font.color Color.green
                    ]
                    (text "Ok")
              else
                el
                    [ alignRight
                    , Font.color Color.red
                    ]
                    (text "Please wait...")
            ]
        , row
            [ padding 5
            , height fill
            ]
            (List.map chunkView chunks)
        ]


nChunks n xs =
    let
        go acc1 acc2 m xs =
            case xs of
                [] ->
                    List.reverse (List.reverse acc2 :: acc1)
                        |> List.filter (\l -> l /= [])

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
