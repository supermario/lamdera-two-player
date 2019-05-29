module Msg exposing (BackendMsg(..), FrontendMsg(..), ToBackend(..), ToFrontend(..))

import Json.Decode
import Json.Encode
import Lamdera.Types exposing (ClientId, WsError)


type FrontendMsg
    = Increment
    | Decrement
    | FNoop


type ToBackend
    = ClientJoin
    | CounterIncremented
    | CounterDecremented


type BackendMsg
    = Noop


type ToFrontend
    = CounterNewValue Int
