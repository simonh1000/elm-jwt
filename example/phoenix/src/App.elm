module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Json.Encode as E exposing (Value)

import Http
import Platform.Cmd exposing (Cmd)
import Task

import Jwt exposing (..)
import Decoders exposing (..)

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
    -- Cmd results
    | LoginSuccess String
    | LoginFail JwtError
    | PostSucess String
    | PostFail JwtError

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        FormInput inputId val ->
            let res = case inputId of
                Uname -> { model | uname = val }
                Pword -> { model | pword = val }
            in (res, Cmd.none)
        Submit ->
            let credentials =
                E.object
                    [ ("username", E.string model.uname)
                    , ("password", E.string model.pword)
                    ]
                |> E.encode 0
            in
            ( model
            , Task.perform
                LoginFail LoginSuccess
                (authenticate tokenStringDecoder "/sessions" credentials)
            )
        TryToken ->
            ( { model | msg = "Attempting to load message..." }
            , case model.token of
                Nothing ->
                    Cmd.none
                Just token ->
                    Jwt.get token dataDecoder "/api/data"
                    `Task.onError` (promote401 token)
                    |> Task.perform PostFail PostSucess
            )
        LoginSuccess token ->
            ( { model | token = Just token, msg = "" }, Cmd.none )
        LoginFail err ->
            ( { model | msg = toString err }, Cmd.none )
        PostSucess msg ->
            ( { model | msg = msg }, Cmd.none )
        PostFail err ->
            case err of
                TokenExpired ->
                    ( { model | msg = "Your token has expired" }, Cmd.none )
                _ ->
                    ( { model | msg = toString err }, Cmd.none )

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
                [ div
                    [  ]
                    [ div
                        [ class "form-group" ]
                        [ label
                            [ for "uname" ]
                            [ text "Username" ]
                        , input
                            -- [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
                            [ onInput (FormInput Uname)
                            , class "form-control"
                            , id "uname"
                            , type' "text"
                            , value model.uname
                            ]
                            [ ]
                        ]
                    , div
                        [ class "form-group" ]
                        [ label
                            [ for "pword" ]
                            [ text "Password" ]
                        , input
                            [ onInput (FormInput Pword)
                            , class "form-control"
                            , id "pword"
                            , type' "password"
                            , value model.pword
                            ]
                            [ ]
                        ]
                    , button
                        [ type' "submit"
                        , class "btn btn-default"
                        ]
                        [ text "Submit" ]
                    ]
                ]
            ]
        , case model.token of
            Nothing -> text ""
            Just tokenString ->
                let token =
                    decodeToken tokenDecoder tokenString
                in
                div []
                    [ p [] [ text <| toString token ]
                    , button
                        [ class "btn btn-warning"
                        , onClick TryToken
                        ]
                        [ text "Try token" ]
                    ]
        , p
            [ style [("color", "red")] ]
            [ text model.msg ]
        ]

-- CMDS
