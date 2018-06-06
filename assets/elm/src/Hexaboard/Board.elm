module Hexaboard.Board exposing (..)

import Dict exposing (..)
import Hexaboard.HexaboardTypes exposing (..)
import Hex as Hex


hexaBoard : Int -> Board
hexaBoard n =
    let
        makeRowTop i =
            List.map (\j -> ( j, i )) (List.range 0 (n + i))

        makeRowBottom i =
            List.map (\j -> ( j, i )) (List.range 0 (2 * n + (n - i)))

        topHalf =
            List.concatMap makeRowTop (List.range 0 n)

        bottomHalf =
            List.concatMap makeRowBottom (List.range (n + 1) (2 * n))
    in
        (topHalf ++ bottomHalf)
            |> List.foldr
                (\( x, y ) res ->
                    Dict.insert ( x, y ) (Cell x y Empty) res
                )
                Dict.empty


isEdge : Int -> Cell -> Bool
isEdge n { xPos, yPos, state } =
    xPos == 0 || yPos == 0 || yPos == 2 * n || (xPos == n + yPos) || (xPos + yPos == 3 * n)


boardWithEdge : Int -> Board -> Board
boardWithEdge n board =
    Dict.map
        (\key cell ->
            { cell
                | state =
                    let
                        toHexString f =
                            round f
                                |> Hex.toString
                                |> String.padLeft 2 '0'
                    in
                        if not <| isEdge n cell then
                            cell.state
                        else if cell.yPos == 0 then
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (n) / 2) - toFloat (cell.xPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#" ++ toHexString (percent * 255) ++ toHexString (percent * 255) ++ "00"
                            in
                                UnPlayable <| Rainbow color_string
                        else if (cell.xPos == 0) && (cell.yPos <= n) then
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (n) / 2) - toFloat (cell.yPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#" ++ toHexString (percent * 255) ++ toHexString (percent * 127) ++ "00"
                            in
                                UnPlayable <| Rainbow color_string
                        else if (cell.xPos == n + cell.yPos) then
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (n) / 2) - toFloat (cell.yPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#00" ++ toHexString (percent * 255) ++ "00"
                            in
                                UnPlayable <| Rainbow color_string
                        else if (cell.xPos == 0) && (cell.yPos >= n) then
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (3 * n) / 2) - toFloat (cell.yPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#" ++ toHexString (percent * 255) ++ "0000"
                            in
                                UnPlayable <| Rainbow color_string
                        else if (cell.xPos + cell.yPos == 3 * n) then
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (3 * n) / 2) - toFloat (cell.yPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#" ++ "0000" ++ toHexString (percent * 255)
                            in
                                UnPlayable <| Rainbow color_string
                        else
                            let
                                percent =
                                    ((toFloat (n) / 2) - abs ((toFloat (n) / 2) - toFloat (cell.xPos))) / (toFloat (n) / 2)

                                color_string =
                                    "#" ++ toHexString (percent * 180) ++ "00" ++ toHexString (percent * 255)
                            in
                                UnPlayable <| Rainbow color_string
            }
        )
        board



--boardWithEdge : Int -> Board -> Board
--boardWithEdge n board =
--    Dict.map
--        (\key cell ->
--            { cell
--                | state =
--                    if isEdge n cell then
--                        UnPlayable Grey
--                    else
--                        cell.state
--            }
--        )
--        board
-------------------------------------------------------------------------------
