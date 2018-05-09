module Main exposing (..)

import Html
import Html.Events
import Json.PrettyPrint


model =
    ""


type Msg
    = UpdateText String


update (UpdateText text) model =
    text


view model =
    Html.div
        []
        [ Html.input
            [ Html.Events.onInput UpdateText ]
            []
        , Html.div
            []
            [ Html.text <| Json.PrettyPrint.stringify model ]
        ]


main =
    Html.beginnerProgram
        { model = model
        , update = update
        , view = view
        }
