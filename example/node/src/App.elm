module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode as Json exposing ( (:=), Value )
import Json.Encode as E

import Platform.Cmd exposing (Cmd)
import Task exposing (toResult)

import Jwt exposing (..)

-- MODEL
type Field
    = Uname
    | Pword

type alias Model =
    { uname : String
    , pword : String
    , token : Maybe String
    , errorMsg : String
    }

init : (Model, Cmd Msg)
init = (Model "testuser" "testpassword" Nothing "", Cmd.none)

type alias JwtToken =
    { id: String
    , username : String
    , iat : Int
    , expiry : Int
    }

tokenDecoder =
    Json.object4 JwtToken
        ("id" := Json.string)
        ("username" := Json.string)
        ("iat" := Json.int)
        ("exp" := Json.int)

-- UPDATE

type Msg
    -- User generated Msg
    = FormInput Field String
    | Submit
    | TryToken
    -- Cmd results
    | LoginSuccess (Result JwtError String)
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
                    "http://localhost:5000/auth"
                    credentials
                    -- |> Task.map Data
                    -- |> Cmd.task
            )
        TryToken ->
            ( model
            , Task.perform
                PostFail PostSucess <|
                getWithJwt
                    (Maybe.withDefault "" model.token)
                    ("data" := Json.string)
                    "http://localhost:5000/test"
                -- |> Task.toResult
                -- |> Task.map Data2
                -- |> Cmd.task
            )
        LoginSuccess possToken ->
            case possToken of
                Result.Ok tokenString ->
                    ( { model | token = Just tokenString, msg = "" }
                    , Cmd.none
                    )
                Result.Err err ->
                    ( { model | msg = toString err }, Cmd.none )
        LoginFail err ->
            ( { model | errorMsg = toString err }, Cmd.none )
        PostSucess msg ->
            ( { model | errorMsg = msg }, Cmd.none )
        PostFail err ->
            ( { model | errorMsg = toString err }, Cmd.none )

-- VIEW

view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [ ] [ text "elm-jwt with node backend" ]
        , p [] [ text "username = testuser, password = testpassword" ]
        , div
            [ class "row" ]
            [ Html.form
                -- [ onSubmit' address Submit
                [ onSubmit Submit
                , class "col s12"
                ]
                [ div
                    [ class "row" ]
                    [ div
                        [ class "input-field col s12" ]
                        [ input
                            -- [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
                            [ onInput (FormInput Uname)
                            , id "uname"
                            , type' "text"
                            ]
                            [ text model.uname ]
                        , label
                            [ for "uname" ]
                            [ text "Username" ]
                        ]
                    , div
                        [ class "input-field col s12" ]
                        [ input
                            [ onInput (FormInput Pword)
                            -- [ on "input" (Json.map (Input Pword) targetValue) (Signal.message address)
                            , id "pword"
                            , type' "password"
                            ]
                            [ text model.pword ]
                        , label
                            [ for "pword" ]
                            [ text "Password" ]
                        , button
                            [ type' "submit"
                            , class "btn waves-effect waves-light"
                            ]
                            [ text "Submit"
                            , i
                            [ class "material-icons right"
                            ]
                            [ text "send" ]
                            ]
                        ]
                    ]
                ]
            ]
        , p [] [ text <|
                    if model.token == Nothing
                        then ""
                        else toString (decodeToken tokenDecoder <| Maybe.withDefault "" model.token) ]
        , p [] [ text model.errorMsg ]
        , button
            [ class "btn waves-effect waves-light"
            , onClick TryToken
            ]
            [ text "try token" ]
        ]

-- onSubmit' address Msg =
--     onWithOptions
--         "submit"
--         {stopPropagation = True, preventDefault = True}
--         (Json.succeed Msg)
--         (Signal.message address)

-- CMDS
