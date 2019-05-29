module Backend exposing (Model, app)

import Dict exposing (..)
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


newPlayerState : Player
newPlayerState =
    { snake = { x = 0, y = 0 }
    , keyState =
        { leftPressed = False
        , rightPressed = False
        , upPressed = False
        , downPressed = False
        }
    }


type alias Model =
    { counter : Int
    , players : Dict ClientId Player
    , clients : Set ClientId
    }


init : ( Model, Cmd BackendMsg )
init =
    ( { counter = 0, players = Dict.empty, clients = Set.empty }, Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


updateFromFrontend : ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend clientId msg model =
    let
        x =
            Debug.log "backendModel" model
    in
    case msg of
        ClientKeyDown key ->
            let
                newPlayer =
                    case Dict.get clientId model.players of
                        Just player ->
                            let
                                keystate =
                                    player.keyState

                                newKeyState =
                                    case key of
                                        Left ->
                                            { keystate | leftPressed = True }

                                        Right ->
                                            { keystate | rightPressed = True }

                                        Up ->
                                            { keystate | upPressed = True }

                                        Down ->
                                            { keystate | downPressed = True }

                                        Reset ->
                                            keystate

                                        Other ->
                                            keystate

                                snake =
                                    player.snake

                                newSnake =
                                    { snake | x = snake.x + 10 }
                            in
                            { player
                                | keyState = newKeyState
                                , -- hack!
                                  snake = newSnake
                            }

                        Nothing ->
                            -- Shouldn't happen...
                            newPlayerState

                newModel =
                    { model | players = Dict.insert clientId newPlayer model.players }
            in
            if key == Reset then
                let
                    ( resetModel, cmds ) =
                        init
                in
                ( resetModel, broadcast model.clients (NewGameState newModel.players) )

            else
                ( newModel, broadcast model.clients (NewGameState newModel.players) )

        ClientKeyUp key ->
            ( model, Cmd.none )

        ClientJoin ->
            let
                newModel =
                    { model
                        | clients = Set.insert clientId model.clients
                        , players = Dict.insert clientId newPlayerState model.players
                    }
            in
            ( newModel
            , sendToFrontend clientId (NewGameState newModel.players)
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
