module Msg exposing (BackendMsg(..), Board, FrontendMsg(..), KeyState, Keys(..), Player, Snake, ToBackend(..), ToFrontend(..))

import Dict exposing (..)
import Json.Decode
import Json.Encode
import Lamdera.Types exposing (ClientId, WsError)


type alias Board =
    { snakes : List Snake
    }


type alias KeyState =
    { leftPressed : Bool
    , rightPressed : Bool
    , upPressed : Bool
    , downPressed : Bool
    }


type alias Snake =
    { x : Int
    , y : Int
    }


type alias Player =
    { snake : Snake
    , keyState : KeyState
    }


type Keys
    = Left
    | Right
    | Up
    | Down


type FrontendMsg
    = KeyDown Keys
    | KeyUp Keys
    | FNoop


type ToBackend
    = ClientJoin
    | ClientKeyUp Keys
    | ClientKeyDown Keys


type BackendMsg
    = Noop


type ToFrontend
    = NewGameState (Dict ClientId Player)
