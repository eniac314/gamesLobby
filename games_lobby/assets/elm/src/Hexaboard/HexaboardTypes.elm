module Hexaboard.HexaboardTypes exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket
import Time exposing (Time, every, second)


type alias Model =
    { wsUrl : String
    , authToken : String
    , authSalt : String
    , phxSocket : Phoenix.Socket.Socket Msg
    , playerInfo : Player
    , presences : Presence.PresenceState Player
    , chatMessageInput : String
    , chatLog : List ChatMessage
    , chatMessageBoxFocused : Bool
    , board : Board
    , gameState : GameState
    }


type Msg
    = Default
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceivePlayerInfo Decode.Value
    | ReceivePresenceState Decode.Value
    | ReceivePresenceDiff Decode.Value
    | UpdateChatLog Decode.Value
    | ServerMsg Decode.Value
    | ServerError Decode.Value
    | ChatMessageInput String
    | SendChatMessage Date
    | ReceiveChatMessage Decode.Value
    | FocusChatMessageBox
    | UnfocusChatMessageBox
    | KeyDown KeyCode
    | RequestDate (Date -> Msg)
    | TimeUpdate Time


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    }


type alias ChatMessage =
    { timeStamp : Date
    , author : Player
    , message : String
    }


type alias Player =
    { onlineAt : String
    , username : Username
    , choice : Maybe Piece
    , turn : Maybe Int
    , score : Int
    , deck : List Piece
    }


defPlayer =
    { onlineAt = ""
    , username = ""
    , choice = Nothing
    , turn = Nothing
    , score = 0
    , deck = []
    }


type alias Board =
    Dict ( Int, Int ) Cell


type GameState
    = PieceSelection
    | TurnSelection
    | Playing
    | EndGame


type alias Cell =
    { xPos : Int
    , yPos : Int
    , state : CellState
    }


type CellState
    = UnPlayable Col
    | Contain Piece
    | Empty


type Col
    = Grey
    | Rainbow String


type alias Piece =
    { value : Int
    , playerId : Int
    }


dummyPiece =
    { value = 0, playerId = -1 }


type alias Username =
    String
