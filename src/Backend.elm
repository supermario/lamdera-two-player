module Backend exposing (Model, app)

import Lamdera.Backend
import Lamdera.Types exposing (..)
import Msg exposing (..)
import Set exposing (Set, map)
import Task
import Time


app =
    Lamdera.Backend.application
        { init = init
        , update = update
        , subscriptions = \m -> Sub.none
        , updateFromFrontend = updateFromFrontend
        }


type alias Model =
    { counter : Int, clients : Set ClientId }


init : ( Model, Cmd BackendMsg )
init =
    ( { counter = 0, clients = Set.empty }, Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


updateFromFrontend : ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend clientId msg model =
    case msg of
        CounterIncremented ->
            ( { model | counter = model.counter + 1 }, sendToFrontend clientId (CounterNewValue (model.counter + 1)) )

        CounterDecremented ->
            ( { model | counter = model.counter - 1 }, sendToFrontend clientId (CounterNewValue (model.counter + 1)) )

        ClientJoin ->
            let
                newModel =
                    { model | clients = Set.insert clientId model.clients }
            in
            ( newModel
            , sendToFrontend clientId (CounterNewValue model.counter)
            )


broadcast clients msg =
    clients
        |> Set.toList
        |> List.map (\clientId -> sendToFrontend clientId msg)
        |> Cmd.batch


sendToFrontend : ClientId -> ToFrontend -> Cmd BackendMsg
sendToFrontend clientId msg =
    sendToFrontendWrapper 1000 clientId (\_ -> Noop) msg


sendToFrontendWrapper : Milliseconds -> ClientId -> (Result WsError () -> Msg.BackendMsg) -> toFrontend -> Cmd Msg.BackendMsg
sendToFrontendWrapper =
    Lamdera.Backend.sendToFrontend
