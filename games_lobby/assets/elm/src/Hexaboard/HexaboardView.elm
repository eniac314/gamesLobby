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
import Hexaboard.HexaboardTypes exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr exposing (id)
import Phoenix.Channel exposing (State(..))


view model =
    Element.layout
        [ padding 15
        , Font.size 18
        ]
    <|
        column []
            [ text "this is a test" ]
