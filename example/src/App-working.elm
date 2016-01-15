module App (init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http exposing (post)
import Json.Decode as Json exposing ( (:=) )
import String
import Base64

import Effects exposing (Effects)
import Task exposing (..)

-- MODEL
type Field
    = Uname
    | Pword

type alias JwtToken =
    { id: String
    , email : String
    , role : String
    , iat  :Int
    , expiry : Int
    }

tokenDecoder =
    Json.object5 JwtToken
        ("id" := Json.string)
        ("email" := Json.string)
        ("role" := Json.string)
        ("iat" := Json.int)
        ("exp" := Json.int)

type alias Model =
    { uname : String
    , pword : String
    , token : Maybe JwtToken
    , errorMsg : String
    }

init : (Model, Effects Action)
init = (Model "" "" Nothing "", Effects.none)

-- UPDATE

type Action
    = Data (Result String String)
    -- = Data (Maybe Http.Response)
    | Input Field String
    | Submit

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Data res ->
            case (res `Result.andThen` (decodeToken tokenDecoder)) of
                Result.Ok tok ->
                    ( { model | token = Just tok }, Effects.none)
                Result.Err e ->
                    ( { model | errorMsg = e }, Effects.none)

        Input inputId val ->
            let res = case inputId of
                Uname -> { model | uname = val }
                Pword -> { model | pword = val }
            in (res, Effects.none)
        Submit ->
            ( model
            -- , loadData "{\"email\": \"foo@foo\",\"password\":11}"
            -- , loadData """{"email": "foo@foo","password":"foo"}"""
            , loadData (
                "{\"email\":\"" ++ model.uname ++
                "\",\"password\":\""++ model.pword ++ "\"}"
                )
            )

-- urlBase64Decode : String -> String
-- urlBase64Decode s =
--     case Base64.decode s of
--         Result.Ok d -> d
--         Result.Err e -> e
decodeToken : Json.Decoder a -> String -> Result String a
decodeToken dec s =
    (case String.split "." s of
        (_ :: b :: _ :: []) -> Base64.decode b
        otherwise -> Result.Err "decodeToken error")
    `Result.andThen` Json.decodeString dec

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div
        [ class "row" ]
        [ h1 [ ] [ text "Hello" ]
        , Html.form
            [ onSubmit' address Submit
            , class "col s12"
            ]
            [ div
                [ class "input-field" ]
                [ input
                    [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
                    -- , placeholder "Placeholder"
                    , id "uname"
                    , type' "text"
                    ]
                    [ text model.uname ]
                , label
                    [ for "uname" ]
                    [ text "Username" ]
                ]
            , div
                [ class "input-field" ]
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
                    [ class "material-icons mdi-navigation-chevron-right"
                    ]
                    [ text "send" ]
                ]
            ]
        , p [] [ text <| toString model.token ]
        , p [] [ text model.errorMsg ]
        ]

onSubmit' address action =
    onWithOptions
        "submit"
        {stopPropagation = True, preventDefault = True}
        (Json.succeed action)
        (Signal.message address)

-- TASKS
loadData : String -> Effects Action
loadData body =
    post' ("token" := Json.string) "http://localhost:5000/auth" (Http.string body)
        |> Task.mapError (\_ -> "http error")
        |> Task.toResult
        |> Task.map Data
        |> Effects.task

post' : Json.Decoder a -> String -> Http.Body -> Task Http.Error a
post' dec url body =
    Http.send Http.defaultSettings
    { verb = "POST"
    , headers = [("Content-type", "application/json")]
    , url = url
    , body = body
    }
        |> Http.fromJson dec
