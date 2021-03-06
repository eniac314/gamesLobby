module Hexaboard.HexaboardTypes exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Dom exposing (Error)
import Element exposing (Device)
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket
import Time exposing (Time, every, second)
import Window exposing (Size)


type alias Model =
    { wsUrl : String
    , authToken : String
    , authSalt : String
    , gameId : String
    , phxSocket : Phoenix.Socket.Socket Msg
    , playerInfo : PresPlayer
    , presences : Presence.PresenceState PresPlayer
    , chatMessageInput : String
    , consoleLog : List ConsoleMsg
    , chatMessageBoxFocused : Bool
    , board : Board
    , choice : Maybe Piece
    , canChooseTurn : Bool
    , choosenTurn : Maybe Int
    , availableTurns : List Int
    , playingOrder : List Int
    , players : List Player
    , deck : List Piece
    , gameState : GameState
    , displayHints : Bool
    , device : Device
    , winSize : Size
    }


type Msg
    = Default
    | DropJson Decode.Value
    | DropRes (Result Error ())
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceivePlayerInfo Decode.Value
    | RequestGameState Decode.Value
    | ReceivePresenceState Decode.Value
    | ReceivePresenceDiff Decode.Value
    | UpdateChatLog Decode.Value
    | UpdateGameState Decode.Value
    | ServerMsg Decode.Value
    | ServerError Decode.Value
    | DebugJson (Decode.Decoder Decode.Value -> Decode.Decoder Decode.Value) Decode.Value
    | AddServerMsg String Date
    | AddServerError String Date
    | AddGameMsg String Date
    | ChatMessageInput String
    | SendChatMessage Date
    | ReceiveChatMessage Decode.Value
    | FocusChatMessageBox
    | UnfocusChatMessageBox
    | KeyDown KeyCode
    | RequestDate (Date -> Msg)
      --| TimeUpdate Time
    | PickUpPiece Piece
    | PiecePickedUp Decode.Value
    | PlayersUpdate Decode.Value
    | PiecesAllSet Decode.Value
    | SelectTurn Int
    | TurnSelected Decode.Value
    | TurnsAllSet Decode.Value
    | PutDownPiece ( Int, Int )
    | PieceDown Decode.Value
    | RoundOver Decode.Value
    | GameOver Decode.Value
    | HideHints
    | ShowHints
    | Resizes Size


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    , gameId : String
    }


type ConsoleMsg
    = ChatMsg ChatMessage
    | ServerComMsg SystemMessage
    | ServerErrorMsg SystemMessage
    | GameMsg SystemMessage


type alias ChatMessage =
    { timeStamp : Date
    , author : PresPlayer
    , message : String
    }


type alias SystemMessage =
    { timeStamp : Date
    , message : String
    }



-- used for player info field and the chat


type alias PresPlayer =
    { onlineAt : String
    , username : Username
    , playerId : Int
    }


type alias Player =
    { username : String
    , playerId : Int
    , score : Int
    , piece : Maybe Piece
    }


defPresPlayer =
    { onlineAt = ""
    , username = ""
    , playerId = -1
    }


type alias Board =
    Dict ( Int, Int ) Cell


type GameState
    = PieceSelection
    | WaitingForEndOfPieceSelection
    | TurnSelection
    | WaitingForOwnTurn
    | Playing
    | WaitingForEndOfRound
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
