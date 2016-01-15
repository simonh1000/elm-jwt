module App (init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode as Json exposing ( (:=), Value )

import Effects exposing (Effects)
import Task exposing (..)

import Jwt exposing (..)

-- MODEL
type Field
    = Uname
    | Pword

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

type alias Model =
    { uname : String
    , pword : String
    , token : Maybe String
    , errorMsg : String
    }

init : (Model, Effects Action)
init = (Model "testuser" "testpassword" Nothing "", Effects.none)

-- UPDATE

type Action
    = Data (Result JwtError String)
    | Data2 (Result Http.Error String)
    | Input Field String
    | Submit
    | TryToken

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Data res ->
            case res of
                Result.Ok tok ->
                    (   { model
                        | token = Just tok
                        , errorMsg = ""
                        }
                    , Effects.none )
                Result.Err e ->
                    ( { model | errorMsg = toString e }, Effects.none)
        Data2 res ->
            case res of
                Result.Ok msg ->
                    ( { model | errorMsg = msg }, Effects.none)
                Result.Err e ->
                    ( { model | errorMsg = toString e }, Effects.none)

        Input inputId val ->
            let res = case inputId of
                Uname -> { model | uname = val }
                Pword -> { model | pword = val }
            in (res, Effects.none)
        Submit ->
            ( model
            , authenticate
                ("token" := Json.string)
                "http://localhost:5000/auth"
                ("{\"username\":\"" ++ model.uname ++ "\",\"password\":\""++ model.pword ++ "\"}")
                    |> Task.map Data
                    |> Effects.task
            )
        TryToken ->
            ( model
            , getWithJwt
                    (Maybe.withDefault "" model.token)
                    ("data" := Json.string)
                    "http://localhost:5000/test"
                |> Task.toResult
                |> Task.map Data2
                |> Effects.task
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div
        [ class "container" ]
        [ h1 [ ] [ text "Hello" ]
        , p [] [ text "user = testuser, password = testpassword" ]
        , div
            [ class "row" ]
            [ Html.form
                [ onSubmit' address Submit
                , class "col s12"
                ]
                [ div
                    [ class "row" ]
                    [ div
                        [ class "input-field col s12" ]
                        [ input
                            [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
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
                            [ on "input" (Json.map (Input Pword) targetValue) (Signal.message address)
                            , id "pword"
                            , type' "password"
                            ]
                            [ text model.pword ]
                        , label
                            [ for "pword" ]
                            [ text "Password" ]
                        ]
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
        , p [] [ text <|
                    if model.token == Nothing
                        then ""
                        else toString (decodeToken tokenDecoder <| Maybe.withDefault "" model.token) ]
        , p [] [ text model.errorMsg ]
        , button
            [ class "btn waves-effect waves-light"
            , onClick address TryToken
            ]
            [ text "try token" ]
        ]

onSubmit' address action =
    onWithOptions
        "submit"
        {stopPropagation = True, preventDefault = True}
        (Json.succeed action)
        (Signal.message address)
