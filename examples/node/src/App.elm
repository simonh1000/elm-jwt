module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)

import Http
import Json.Encode as E exposing (Value)

import Jwt exposing (..)
import Decoders exposing (..)

authUrl = "/auth"
-- authUrl = "/sessions"

-- MODEL
type Field
    = Uname
    | Pword

type alias Model =
    { uname : String
    , pword : String
    , token : Maybe String
    , msg : String
    }

init : (Model, Cmd Msg)
init = (Model "testuser" "testpassword" Nothing "", Cmd.none)

-- UPDATE

type Msg
    -- User generated Msg
    = FormInput Field String
    | Submit
    | TryToken
    | TryWithInvalidToken
    -- Cmd results
    | Auth (Result Http.Error String)
    | GetResult (Result JwtError String)
    | InvalidTokenResult (Result JwtError String)

update : Msg -> Model -> (Model, Cmd Msg)
update message model =
    case message of
        FormInput inputId val ->
            let res = case inputId of
                Uname ->
                    { model | uname = val }
                Pword ->
                    { model | pword = val }
            in res ! []
        Submit ->
            ( model
            , submitCredentials model
            )
        TryToken ->
            case model.token of
                Just token ->
                    { model | msg = "Contacting server..." } ! [ tryToken token ]
                Nothing ->
                    { model | msg = "No token" } ! []
        TryWithInvalidToken ->
            ( { model | msg = "Contacting server..." }
            , tryWithInvalidToken
            )
        Auth (Result.Ok token) ->
            { model | token = Just token, msg = "" } ! []
        Auth (Result.Err err) ->
            { model | msg = toString err } ! []
        GetResult (Result.Ok msg) ->
            { model | msg = msg } ! []
        GetResult (Result.Err err) ->
            case err of
                Jwt.TokenExpired ->
                    { model | msg = "Token expired" } ! []
                _ ->
                    { model | msg = toString err } ! []
        InvalidTokenResult (Result.Ok msg) ->
            { model | msg = msg } ! []
        InvalidTokenResult (Result.Err err) ->
            { model | msg = toString err } ! []
        -- _ ->
        --     ( { model | msg = toString message }, Cmd.none )


-- VIEW

view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [ ] [ text "elm-jwt with Phoenix backend" ]
        , p [] [ text "username = testuser, password = testpassword" ]
        , div
            [ class "row" ]
            [ Html.form
                [ onSubmit Submit
                , class "col-xs-12"
                ]
                [ div []
                    [ div
                        [ class "form-group" ]
                        [ label
                            [ for "uname" ]
                            [ text "Username" ]
                        , input
                            -- [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
                            [ onInput (FormInput Uname)
                            , class "form-control"
                            , value model.uname
                            ] []
                        ]
                    , div
                        [ class "form-group" ]
                        [ label
                            [ for "pword" ]
                            [ text "Password" ]
                        , input
                            [ onInput (FormInput Pword)
                            , class "form-control"
                            , value model.pword
                            ] []
                        ]
                    , button
                        [ type_ "submit"
                        , class "btn btn-default"
                        ]
                        [ text "Submit" ]
                    ]
                ]
            ]
        , case model.token of
            Nothing ->
                text ""
            Just tokenString ->
                let token =
                    decodeToken tokenDecoder tokenString
                in
                div []
                    [ p [] [ text <| toString token ]
                    , button
                        [ class "btn btn-primary"
                        , onClick TryToken
                        ]
                        [ text "Try token" ]
                    , button
                        [ class "btn btn-warning"
                        , onClick TryWithInvalidToken
                        ]
                        [ text "Try bad token" ]
                    , p [] [ text "Wait 30 seconds and try again too" ]
                    ]
        , p
            [ style [("color", "red")] ]
            [ text model.msg ]
        ]

-- COMMANDS

submitCredentials : Model -> Cmd Msg
submitCredentials model =
    E.object
        [ ("username", E.string model.uname)
        , ("password", E.string model.pword)
        ]
    |> authenticate Auth authUrl tokenStringDecoder

tryToken : String -> Cmd Msg
tryToken token =
    Jwt.get_ token "/api/data" dataDecoder
    |> Task.perform GetResult

tryWithInvalidToken : Cmd Msg
tryWithInvalidToken =
    Jwt.get_ "invalidToken" "/api/data" dataDecoder
    |> Task.perform InvalidTokenResult
