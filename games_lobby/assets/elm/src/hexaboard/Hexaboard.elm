module Hexaboard exposing (..)

import Html exposing (..)


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    }


type alias Model =
    String


type Msg
    = Default


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init flags =
    "" ! []


view model =
    text "this is a test"


update msg model =
    model ! []


subscriptions model =
    Sub.none
