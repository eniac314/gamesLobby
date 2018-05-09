module Json.PrettyPrint exposing (toString, stringify)

{-| Hello
@docs toString, stringify
-}

import Json.Decode
import Dict exposing (Dict)


type InternalJson
    = JsonString String
    | JsonNumber Float
    | JsonBool Bool
    | JsonObject (Dict String InternalJson)
    | JsonList (List InternalJson)
    | JsonNull


decodeToInternalJson : Json.Decode.Decoder InternalJson
decodeToInternalJson =
    Json.Decode.oneOf
        [ Json.Decode.map JsonString Json.Decode.string
        , Json.Decode.map JsonNumber Json.Decode.float
        , Json.Decode.map JsonBool Json.Decode.bool
        , Json.Decode.map JsonObject (Json.Decode.lazy (\_ -> Json.Decode.dict decodeToInternalJson))
        , Json.Decode.map JsonList (Json.Decode.lazy (\_ -> (Json.Decode.list decodeToInternalJson)))
        , Json.Decode.null JsonNull
        ]


{-| Takes a JSON value and turns it into a string
-}
toString : Json.Decode.Value -> String
toString value =
    case Json.Decode.decodeValue decodeToInternalJson value of
        Err e ->
            e

        Ok v ->
            internalJsonToString 0 v


{-| Takes a JSON string and formats it
-}
stringify : String -> String
stringify value =
    case Json.Decode.decodeString decodeToInternalJson value of
        Err e ->
            e

        Ok v ->
            internalJsonToString 0 v


internalJsonToString : Int -> InternalJson -> String
internalJsonToString n json =
    let
        spacer n =
            String.repeat 0 "  "
    in
        case json of
            JsonString str ->
                "\"" ++ str ++ "\""

            JsonNumber num ->
                Basics.toString num

            JsonBool bool ->
                if bool then
                    "true"
                else
                    "false"

            JsonObject object ->
                Dict.toList object
                    |> List.map (\( key, value ) -> "\"" ++ key ++ "\" : " ++ internalJsonToString (n + 1) value)
                    |> String.join (spacer n ++ ",\n")
                    |> (\x -> spacer n ++ "{\n" ++ x ++ "}")

            JsonList list ->
                List.map (internalJsonToString n) list
                    |> String.join ", "
                    |> (\x -> "[" ++ x ++ "]")

            JsonNull ->
                "null"
