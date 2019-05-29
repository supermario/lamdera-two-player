module Frontend exposing (Model, app, subscriptions)

import Browser.Dom as Dom
import Browser.Events as Keyboard
import Debug exposing (toString)
import Dict exposing (..)
import Html exposing (Html, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as Decode
import Lamdera.Frontend
import Lamdera.Types exposing (..)
import Msg exposing (..)
import Task


{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.Frontend.application is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    Lamdera.Frontend.application
        { init = \_ _ -> init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "Lamdera board app"
                , body = [ view model ]
                }
        , subscriptions = subscriptions
        , onUrlChange = \_ -> FNoop
        , onUrlRequest = \_ -> FNoop
        }


subscriptions model =
    Sub.batch
        [ Keyboard.onKeyDown keyDecoderDown
        , Keyboard.onKeyUp keyDecoderUp
        ]


type alias Model =
    { players : Dict ClientId Player
    }


init : ( Model, Cmd FrontendMsg )
init =
    ( { players = Dict.empty }, Cmd.none )


view : Model -> Html FrontendMsg
view model =
    Html.div []
        [ Html.div
            [ style "width" "400px"
            , style "height" "400px"
            , style "position" "relative"
            , style "background-color" "#000"
            ]
            (model.players |> Dict.toList |> List.map Tuple.second |> List.map renderPlayer)
        ]


keyDecoderDown : Decode.Decoder FrontendMsg
keyDecoderDown =
    Decode.map toDirectionDown (Decode.field "key" Decode.string)


toDirectionDown : String -> FrontendMsg
toDirectionDown string =
    case string of
        "ArrowLeft" ->
            KeyDown Left

        "ArrowRight" ->
            KeyDown Right

        "ArrowUp" ->
            KeyDown Up

        "ArrowDown" ->
            KeyDown Down

        _ ->
            KeyDown Up


keyDecoderUp : Decode.Decoder FrontendMsg
keyDecoderUp =
    Decode.map toDirectionUp (Decode.field "key" Decode.string)


toDirectionUp : String -> FrontendMsg
toDirectionUp string =
    case string of
        "ArrowLeft" ->
            KeyUp Left

        "ArrowRight" ->
            KeyUp Right

        "ArrowUp" ->
            KeyUp Up

        "ArrowDown" ->
            KeyUp Down

        _ ->
            KeyUp Up


renderPlayer : Player -> Html msg
renderPlayer player =
    Html.div
        [ style "position" "absolute"
        , style "left" <| String.fromInt player.snake.x ++ "px"
        , style "top" <| String.fromInt player.snake.y ++ "px"
        , style "width" "20px"
        , style "height" "20px"
        , style "background-color" "#FFCE42"
        ]
        []


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    let
        x =
            Debug.log "model" model
    in
    case msg of
        KeyDown key ->
            case key of
                Left ->
                    ( model, sendToBackend (ClientKeyUp Left) )

                Right ->
                    ( model, sendToBackend (ClientKeyUp Right) )

                Up ->
                    ( model, sendToBackend (ClientKeyUp Up) )

                Down ->
                    ( model, sendToBackend (ClientKeyUp Down) )

        KeyUp key ->
            case key of
                Left ->
                    ( model, sendToBackend (ClientKeyDown Left) )

                Right ->
                    ( model, sendToBackend (ClientKeyDown Right) )

                Up ->
                    ( model, sendToBackend (ClientKeyDown Up) )

                Down ->
                    ( model, sendToBackend (ClientKeyDown Down) )

        FNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NewGameState players ->
            ( { model | players = players }, Cmd.none )


sendToBackend : Msg.ToBackend -> Cmd Msg.FrontendMsg
sendToBackend msg =
    sendToBackendWrapper 1000 (\_ -> FNoop) msg


sendToBackendWrapper : Milliseconds -> (Result WsError () -> Msg.FrontendMsg) -> Msg.ToBackend -> Cmd Msg.FrontendMsg
sendToBackendWrapper =
    Lamdera.Frontend.sendToBackend
