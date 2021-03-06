module Hexaboard.Data exposing (..)

import Dict exposing (..)


shifumiTable =
    Dict.fromList
        [ ( ( 0, 0 ), 0 )
        , ( ( 0, 1 ), 1 )
        , ( ( 0, 2 ), -1 )
        , ( ( 0, 3 ), 1 )
        , ( ( 0, 4 ), -1 )
        , ( ( 0, 5 ), 1 )
        , ( ( 0, 6 ), -1 )
        , ( ( 0, 7 ), 1 )
        , ( ( 0, 8 ), -1 )
        , ( ( 0, 9 ), 1 )
        , ( ( 0, 10 ), -1 )
        , ( ( 0, 11 ), 1 )
        , ( ( 0, 12 ), -1 )
        , ( ( 0, 13 ), 1 )
        , ( ( 0, 14 ), -1 )
        , ( ( 1, 0 ), -1 )
        , ( ( 1, 1 ), 0 )
        , ( ( 1, 2 ), 1 )
        , ( ( 1, 3 ), -1 )
        , ( ( 1, 4 ), -1 )
        , ( ( 1, 5 ), -1 )
        , ( ( 1, 6 ), 1 )
        , ( ( 1, 7 ), 1 )
        , ( ( 1, 8 ), 1 )
        , ( ( 1, 9 ), -2 )
        , ( ( 1, 10 ), -2 )
        , ( ( 1, 11 ), -2 )
        , ( ( 1, 12 ), 2 )
        , ( ( 1, 13 ), 2 )
        , ( ( 1, 14 ), 2 )
        , ( ( 2, 0 ), 1 )
        , ( ( 2, 1 ), -1 )
        , ( ( 2, 2 ), 0 )
        , ( ( 2, 3 ), 1 )
        , ( ( 2, 4 ), 1 )
        , ( ( 2, 5 ), 1 )
        , ( ( 2, 6 ), -1 )
        , ( ( 2, 7 ), -1 )
        , ( ( 2, 8 ), -1 )
        , ( ( 2, 9 ), 2 )
        , ( ( 2, 10 ), 2 )
        , ( ( 2, 11 ), 2 )
        , ( ( 2, 12 ), -2 )
        , ( ( 2, 13 ), -2 )
        , ( ( 2, 14 ), -2 )
        , ( ( 3, 0 ), -1 )
        , ( ( 3, 1 ), 1 )
        , ( ( 3, 2 ), -1 )
        , ( ( 3, 3 ), 0 )
        , ( ( 3, 4 ), -1 )
        , ( ( 3, 5 ), 1 )
        , ( ( 3, 6 ), 1 )
        , ( ( 3, 7 ), -1 )
        , ( ( 3, 8 ), 1 )
        , ( ( 3, 9 ), -2 )
        , ( ( 3, 10 ), -2 )
        , ( ( 3, 11 ), 2 )
        , ( ( 3, 12 ), -2 )
        , ( ( 3, 13 ), 2 )
        , ( ( 3, 14 ), 2 )
        , ( ( 4, 0 ), 1 )
        , ( ( 4, 1 ), 1 )
        , ( ( 4, 2 ), -1 )
        , ( ( 4, 3 ), 1 )
        , ( ( 4, 4 ), 0 )
        , ( ( 4, 5 ), -1 )
        , ( ( 4, 6 ), 1 )
        , ( ( 4, 7 ), -1 )
        , ( ( 4, 8 ), -1 )
        , ( ( 4, 9 ), 2 )
        , ( ( 4, 10 ), -2 )
        , ( ( 4, 11 ), 2 )
        , ( ( 4, 12 ), -2 )
        , ( ( 4, 13 ), -2 )
        , ( ( 4, 14 ), 2 )
        , ( ( 5, 0 ), -1 )
        , ( ( 5, 1 ), 1 )
        , ( ( 5, 2 ), -1 )
        , ( ( 5, 3 ), -1 )
        , ( ( 5, 4 ), 1 )
        , ( ( 5, 5 ), 0 )
        , ( ( 5, 6 ), -1 )
        , ( ( 5, 7 ), 1 )
        , ( ( 5, 8 ), 1 )
        , ( ( 5, 9 ), -2 )
        , ( ( 5, 10 ), 2 )
        , ( ( 5, 11 ), -2 )
        , ( ( 5, 12 ), 2 )
        , ( ( 5, 13 ), 2 )
        , ( ( 5, 14 ), -2 )
        , ( ( 6, 0 ), 1 )
        , ( ( 6, 1 ), -1 )
        , ( ( 6, 2 ), 1 )
        , ( ( 6, 3 ), -1 )
        , ( ( 6, 4 ), -1 )
        , ( ( 6, 5 ), 1 )
        , ( ( 6, 6 ), 0 )
        , ( ( 6, 7 ), -1 )
        , ( ( 6, 8 ), 1 )
        , ( ( 6, 9 ), -2 )
        , ( ( 6, 10 ), 2 )
        , ( ( 6, 11 ), 2 )
        , ( ( 6, 12 ), -2 )
        , ( ( 6, 13 ), -2 )
        , ( ( 6, 14 ), 2 )
        , ( ( 7, 0 ), -1 )
        , ( ( 7, 1 ), -1 )
        , ( ( 7, 2 ), 1 )
        , ( ( 7, 3 ), 1 )
        , ( ( 7, 4 ), 1 )
        , ( ( 7, 5 ), -1 )
        , ( ( 7, 6 ), 1 )
        , ( ( 7, 7 ), 0 )
        , ( ( 7, 8 ), -1 )
        , ( ( 7, 9 ), 2 )
        , ( ( 7, 10 ), 2 )
        , ( ( 7, 11 ), -2 )
        , ( ( 7, 12 ), 2 )
        , ( ( 7, 13 ), -2 )
        , ( ( 7, 14 ), -2 )
        , ( ( 8, 0 ), 1 )
        , ( ( 8, 1 ), -1 )
        , ( ( 8, 2 ), 1 )
        , ( ( 8, 3 ), -1 )
        , ( ( 8, 4 ), 1 )
        , ( ( 8, 5 ), -1 )
        , ( ( 8, 6 ), -1 )
        , ( ( 8, 7 ), 1 )
        , ( ( 8, 8 ), 0 )
        , ( ( 8, 9 ), 2 )
        , ( ( 8, 10 ), -2 )
        , ( ( 8, 11 ), -2 )
        , ( ( 8, 12 ), 2 )
        , ( ( 8, 13 ), 2 )
        , ( ( 8, 14 ), -2 )
        , ( ( 9, 0 ), -1 )
        , ( ( 9, 1 ), 2 )
        , ( ( 9, 2 ), -2 )
        , ( ( 9, 3 ), 2 )
        , ( ( 9, 4 ), -2 )
        , ( ( 9, 5 ), 2 )
        , ( ( 9, 6 ), 2 )
        , ( ( 9, 7 ), -2 )
        , ( ( 9, 8 ), -2 )
        , ( ( 9, 9 ), 0 )
        , ( ( 9, 10 ), -1 )
        , ( ( 9, 11 ), 1 )
        , ( ( 9, 12 ), 1 )
        , ( ( 9, 13 ), -1 )
        , ( ( 9, 14 ), 1 )
        , ( ( 10, 0 ), 1 )
        , ( ( 10, 1 ), 2 )
        , ( ( 10, 2 ), -2 )
        , ( ( 10, 3 ), 2 )
        , ( ( 10, 4 ), 2 )
        , ( ( 10, 5 ), -2 )
        , ( ( 10, 6 ), -2 )
        , ( ( 10, 7 ), -2 )
        , ( ( 10, 8 ), 2 )
        , ( ( 10, 9 ), 1 )
        , ( ( 10, 10 ), 0 )
        , ( ( 10, 11 ), -1 )
        , ( ( 10, 12 ), 1 )
        , ( ( 10, 13 ), -1 )
        , ( ( 10, 14 ), -1 )
        , ( ( 11, 0 ), -1 )
        , ( ( 11, 1 ), 2 )
        , ( ( 11, 2 ), -2 )
        , ( ( 11, 3 ), -2 )
        , ( ( 11, 4 ), -2 )
        , ( ( 11, 5 ), 2 )
        , ( ( 11, 6 ), -2 )
        , ( ( 11, 7 ), 2 )
        , ( ( 11, 8 ), 2 )
        , ( ( 11, 9 ), -1 )
        , ( ( 11, 10 ), 1 )
        , ( ( 11, 11 ), 0 )
        , ( ( 11, 12 ), -1 )
        , ( ( 11, 13 ), 1 )
        , ( ( 11, 14 ), 1 )
        , ( ( 12, 0 ), 1 )
        , ( ( 12, 1 ), -2 )
        , ( ( 12, 2 ), 2 )
        , ( ( 12, 3 ), 2 )
        , ( ( 12, 4 ), 2 )
        , ( ( 12, 5 ), -2 )
        , ( ( 12, 6 ), 2 )
        , ( ( 12, 7 ), -2 )
        , ( ( 12, 8 ), -2 )
        , ( ( 12, 9 ), -1 )
        , ( ( 12, 10 ), -1 )
        , ( ( 12, 11 ), 1 )
        , ( ( 12, 12 ), 0 )
        , ( ( 12, 13 ), -1 )
        , ( ( 12, 14 ), 1 )
        , ( ( 13, 0 ), -1 )
        , ( ( 13, 1 ), -2 )
        , ( ( 13, 2 ), 2 )
        , ( ( 13, 3 ), -2 )
        , ( ( 13, 4 ), 2 )
        , ( ( 13, 5 ), -2 )
        , ( ( 13, 6 ), 2 )
        , ( ( 13, 7 ), 2 )
        , ( ( 13, 8 ), -2 )
        , ( ( 13, 9 ), 1 )
        , ( ( 13, 10 ), 1 )
        , ( ( 13, 11 ), -1 )
        , ( ( 13, 12 ), 1 )
        , ( ( 13, 13 ), 0 )
        , ( ( 13, 14 ), -1 )
        , ( ( 14, 0 ), 1 )
        , ( ( 14, 1 ), -2 )
        , ( ( 14, 2 ), 2 )
        , ( ( 14, 3 ), -2 )
        , ( ( 14, 4 ), -2 )
        , ( ( 14, 5 ), 2 )
        , ( ( 14, 6 ), -2 )
        , ( ( 14, 7 ), 2 )
        , ( ( 14, 8 ), 2 )
        , ( ( 14, 9 ), -1 )
        , ( ( 14, 10 ), 1 )
        , ( ( 14, 11 ), -1 )
        , ( ( 14, 12 ), -1 )
        , ( ( 14, 13 ), 1 )
        , ( ( 14, 14 ), 0 )
        ]
