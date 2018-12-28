module Main exposing (main)

import Browser
import Decoders exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as E exposing (Value)
import Jwt exposing (..)
import Jwt.Http
import Task exposing (Task)



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


init : flags -> ( Model, Cmd Msg )
init _ =
    ( Model "testuser" "testpassword" Nothing "", Cmd.none )



-- UPDATE


type Msg
    = FormInput Field String -- updating form input
    | Login -- onClick Login
      -- after receiving token
    | TryToken String -- token , onClick button
      -- Cmd results
    | OnLoginResponse (Result Http.Error String)
    | OnDataResponse String (Result Http.Error String)
    | OnTokenExpiryCheck (Result JwtError Bool)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "" message of
        FormInput inputId val ->
            case inputId of
                Uname ->
                    ( { model | uname = val }, Cmd.none )

                Pword ->
                    ( { model | pword = val }, Cmd.none )

        Login ->
            ( model, submitCredentials model )

        TryToken token ->
            ( { model | msg = "Contacting server..." }
            , tryToken token
            )

        OnLoginResponse res ->
            case res of
                Ok token ->
                    ( { model | token = Just token, msg = "" }, Cmd.none )

                Err err ->
                    ( { model | msg = handleHttpError err }, Cmd.none )

        OnDataResponse token res ->
            case res of
                Ok msg ->
                    ( { model | msg = msg }, Cmd.none )

                Err httpErr ->
                    if Jwt.Http.is401 httpErr then
                        ( { model | msg = "Unauthorized, checking whether expired" }
                        , Jwt.checkTokenExpiry token
                            |> Task.attempt OnTokenExpiryCheck
                        )

                    else
                        ( { model | msg = handleHttpError httpErr }, Cmd.none )

        OnTokenExpiryCheck res ->
            let
                msg =
                    case res of
                        Ok True ->
                            "Expired"

                        Ok False ->
                            "Not expired!"

                        Err jwtErr ->
                            Jwt.errorToString jwtErr
            in
            ( { model | msg = msg }, Cmd.none )


handleHttpError : Http.Error -> String
handleHttpError error =
    case error of
        Http.BadStatus status ->
            "BadStatus: " ++ String.fromInt status

        Http.BadBody s ->
            "BadBody: " ++ s

        _ ->
            Debug.toString error


errorDecoder : Decode.Decoder Decode.Value
errorDecoder =
    Decode.field "errors" Decode.value



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [] [ text "elm-jwt example" ]
        , p [] [ text "username = testuser, password = testpassword" ]
        , div
            [ class "row" ]
            [ Html.form
                [ onSubmit Login
                , class "col-xs-12"
                ]
                [ div []
                    [ div
                        [ class "form-group" ]
                        [ label [ for "uname" ] [ text "Username" ]
                        , input
                            [ onInput (FormInput Uname)
                            , class "form-control"
                            , value model.uname
                            ]
                            []
                        ]
                    , div
                        [ class "form-group" ]
                        [ label [ for "pword" ] [ text "Password" ]
                        , input
                            [ onInput (FormInput Pword)
                            , class "form-control"
                            , value model.pword
                            ]
                            []
                        ]
                    , button
                        [ type_ "submit"
                        , class "btn btn-default"
                        ]
                        [ text "Login" ]
                    ]
                ]
            ]
        , case model.token of
            Nothing ->
                text ""

            Just tokenString ->
                let
                    decodeHeader =
                        Decode.map2 (\a b -> ( a, b ))
                            (Decode.field "typ" Decode.string)
                            (Decode.field "alg" Decode.string)

                    header =
                        tokenString
                            |> Jwt.getTokenHeader
                            |> Result.mapError Jwt.errorToString
                            |> Result.andThen (Decode.decodeString decodeHeader >> Result.mapError Decode.errorToString)

                    token =
                        case decodeToken Decoders.tokenDecoder tokenString of
                            Ok t ->
                                Debug.toString t

                            Err err ->
                                Jwt.errorToString err
                in
                div []
                    [ p [] [ text token ]
                    , p [] [ text <| Debug.toString header ]
                    , mkButton (TryToken tokenString) "Try token"
                    , mkButton (TryToken <| "xx" ++ tokenString) "Try invalid token"

                    -- , mkButton TryErrorRoute "Try route with insufficient priviledges"
                    , p [] [ text "Wait 30 seconds and try again too" ]
                    ]
        , p [ class "warning" ] [ text model.msg ]
        ]


mkButton : msg -> String -> Html msg
mkButton msg str =
    button
        [ class "btn btn-warning"
        , onClick msg
        ]
        [ text str ]



-- COMMANDS


serverUrl : String
serverUrl =
    "http://localhost:5000"


submitCredentials : Model -> Cmd Msg
submitCredentials model =
    let
        body =
            [ ( "username", E.string model.uname )
            , ( "password", E.string model.pword )
            ]
                |> E.object
                |> Http.jsonBody
    in
    Http.post
        { url = serverUrl ++ "/sessions"
        , body = body
        , expect = Http.expectJson OnLoginResponse tokenStringDecoder
        }


tryToken : String -> Cmd Msg
tryToken token =
    Jwt.Http.get token
        { url = serverUrl ++ "/api/data"
        , expect = Http.expectJson (OnDataResponse token) dataDecoder
        }



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = \m -> Browser.Document "elm-jwt test" [ view m ]
        , subscriptions = \_ -> Sub.none
        }
