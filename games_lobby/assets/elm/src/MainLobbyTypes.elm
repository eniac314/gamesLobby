module MainLobbyTypes exposing (..)

import Date exposing (..)
import Dict exposing (..)
import Dom exposing (Error)
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (..)
import Phoenix.Channel
import Phoenix.Presence as Presence
import Phoenix.Push
import Phoenix.Socket


type alias Flags =
    { authToken : String
    , authSalt : String
    , wsUrl : String
    }


type alias Model =
    { wsUrl : String
    , authToken : String
    , authSalt : String
    , phxSocket : Phoenix.Socket.Socket Msg
    , playerInfo : Player
    , log : String
    , errors : String
    , presences : Presence.PresenceState Player
    , chatMessageInput : String
    , chatLog : List ChatMessage
    , chatMessageBoxFocused : Bool
    , gamesMeta : Dict String GameMeta
    , gamesSetup : Dict String GameSetup
    , currentSelectedGame : Maybe GameMeta

    --, currentlyHosting : Bool
    --, currentlyJoining : Bool
    }


type alias GameMeta =
    { name : String
    , minPlayers : Int
    , maxPlayers : Int
    , hasIA : Bool
    }


type alias GameId =
    ( GameMeta, Int )


type alias Username =
    String


type alias GameSetup =
    { gameMeta : GameMeta
    , joined : List Username
    , host : Maybe Username
    , gameId : GameId
    }


type alias ChatMessage =
    { timeStamp : Date
    , author : Player
    , message : String
    }


type alias Player =
    { onlineAt : String
    , username : Username
    }


defPlayer =
    Player "" ""


type Msg
    = Default
    | DropRes (Result Error ())
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel String
    | JoinChannels
    | LeaveChannel String
    | ReceivePlayerInfo Decode.Value
    | ReceivePresenceState Decode.Value
    | ReceivePresenceDiff Decode.Value
    | UpdateChatLog Decode.Value
    | ServerMsg Decode.Value
    | ServerError Decode.Value
    | ChatMessageInput String
    | SendChatMessage Date
    | ReceiveChatMessage Decode.Value
    | ReceiveGamesMeta Decode.Value
    | ReceiveGamesSetup Decode.Value
    | FocusChatMessageBox
    | UnfocusChatMessageBox
    | KeyDown KeyCode
    | RequestDate (Date -> Msg)
    | SelectGame GameMeta
    | UnSelectGame
    | NewGame
    | DeleteGame GameId
    | JoinGame GameId
    | LeaveGame GameId
    | StartGame GameId
