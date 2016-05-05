module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Encode as E
import Json.Decode as Json exposing ( (:=), Value )

import Platform.Cmd exposing (Cmd)
import Task exposing (toResult)

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
    | PostFail Http.Error

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
                LoginFail LoginSuccess <|
                authenticate
                    ("token" := Json.string)
                    "/sessions"
                    credentials
            )
        TryToken ->
            ( { model | msg = "Attempting to load message..." }
            , case model.token of
                Nothing ->
                    Cmd.none
                Just token ->
                    Task.perform
                        PostFail PostSucess <|
                        getWithJwt
                            token
                            ("data" := Json.string)
                            "/api/data"
            )
        LoginSuccess tokenString ->
            ( { model | token = Just tokenString, msg = "" }
            , Cmd.none
            )
        LoginFail err ->
            ( { model | msg = toString err }, Cmd.none )
        PostSucess msg ->
            ( { model | msg = msg }, Cmd.none )
        PostFail err ->
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
                -- [ onSubmit' address Submit
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

-- onSubmit' address Msg =
--     onWithOptions
--         "submit"
--         {stopPropagation = True, preventDefault = True}
--         (Json.succeed Msg)
--         (Signal.message address)

-- CMDS
