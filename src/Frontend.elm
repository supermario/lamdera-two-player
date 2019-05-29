module Frontend exposing (Model, app)

import Browser.Dom as Dom
import Debug exposing (toString)
import Html exposing (Html, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as D
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
                { title = "Lamdera counter app"
                , body = [ view model ]
                }
        , subscriptions = \m -> Sub.none
        , onUrlChange = \_ -> FNoop
        , onUrlRequest = \_ -> FNoop
        }


type alias Model =
    { counter : Int }


init : ( Model, Cmd FrontendMsg )
init =
    ( { counter = 0 }, Cmd.none )


view : Model -> Html FrontendMsg
view model =
    Html.div []
        [ Html.button [ onClick Increment ] [ text "+" ]
        , Html.text (String.fromInt model.counter)
        , Html.button [ onClick Decrement ] [ text "-" ]
        ]


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )

        Decrement ->
            ( { model | counter = model.counter - 1 }, sendToBackend CounterDecremented )

        FNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        CounterNewValue newValue ->
            ( { model | counter = newValue }, Cmd.none )


sendToBackend : Msg.ToBackend -> Cmd Msg.FrontendMsg
sendToBackend msg =
    sendToBackendWrapper 1000 (\_ -> FNoop) msg


sendToBackendWrapper : Milliseconds -> (Result WsError () -> Msg.FrontendMsg) -> Msg.ToBackend -> Cmd Msg.FrontendMsg
sendToBackendWrapper =
    Lamdera.Frontend.sendToBackend
