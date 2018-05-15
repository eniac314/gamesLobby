module Hexaboard.Board exposing (..)

import Dict exposing (..)
import Hexaboard.HexaboardTypes exposing (..)


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
                    if isEdge n cell then
                        UnPlayable Grey
                    else
                        cell.state
            }
        )
        board



-------------------------------------------------------------------------------
