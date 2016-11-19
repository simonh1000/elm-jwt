module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Http
import Json.Encode as E exposing (Value)
import Json.Decode as Json exposing (field)
import Jwt exposing (..)
import Decoders exposing (..)


authUrl =
    "/sessions"



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


init : ( Model, Cmd Msg )
init =
    Model "testuser" "testpassword" Nothing "" ! []



-- UPDATE


type
    Msg
    -- User generated Msg
    = Login
    | TryToken
    | TryInvalidToken
    | TryErrorRoute
      -- Component messages
    | FormInput Field String
      -- Cmd results
    | Auth (Result Http.Error String)
    | GetResult (Result JwtError String)
    | ErrorRouteResult (Result JwtError String)
    | ServerFail_ JwtError


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "" message of
        FormInput inputId val ->
            case inputId of
                Uname ->
                    { model | uname = val } ! []

                Pword ->
                    { model | pword = val } ! []

        Login ->
            model ! [ submitCredentials model ]

        TryToken ->
            ( { model | msg = "Contacting server..." }
            , model.token
                |> Maybe.map tryToken
                |> Maybe.withDefault Cmd.none
            )

        TryInvalidToken ->
            { model | msg = "Contacting server..." } ! [ tryToken "invalid token" ]

        TryErrorRoute ->
            ( { model | msg = "Contacting server..." }
            , model.token
                |> Maybe.map tryErrorRoute
                |> Maybe.withDefault Cmd.none
            )

        Auth res ->
            case res of
                Result.Ok token ->
                    { model | token = Just token, msg = "" } ! []

                Result.Err err ->
                    { model | msg = getPhoenixError err } ! []

        GetResult res ->
            case res of
                Ok msg ->
                    { model | msg = msg } ! []

                Err jwtErr ->
                    failHandler_ ServerFail_ jwtErr model

        ErrorRouteResult res ->
            case res of
                Ok r ->
                    { model | msg = toString r } ! []

                Err jwtErr ->
                    failHandler_ ServerFail_ jwtErr model

        ServerFail_ jwtErr ->
            failHandler_ ServerFail_ jwtErr model


failHandler_ : (JwtError -> Msg) -> JwtError -> Model -> ( Model, Cmd Msg )
failHandler_ msgCreator jwtErr model =
    case model.token of
        Just token ->
            failHandler ServerFail_ token jwtErr model

        Nothing ->
            { model | msg = toString jwtErr } ! []



-- We recurse at most once because Jwt.checkTokenExpirey cannot return Jwt.Unauthorized


failHandler : (JwtError -> msg) -> String -> JwtError -> { model | msg : String } -> ( { model | msg : String }, Cmd msg )
failHandler msgCreator token jwtErr model =
    case jwtErr of
        Jwt.Unauthorized ->
            ( { model | msg = "Unauthorized" }
            , Jwt.checkTokenExpirey token
                |> Task.perform msgCreator
            )

        Jwt.TokenExpired ->
            { model | msg = "Token expired" } ! []

        Jwt.TokenNotExpired ->
            { model | msg = "Insufficient priviledges" } ! []

        Jwt.HttpError err ->
            { model | msg = getPhoenixError err } ! []

        _ ->
            { model | msg = toString jwtErr } ! []


getPhoenixError : Http.Error -> String
getPhoenixError error =
    case error of
        Http.BadStatus response ->
            let
                decodedError =
                    response.body
                        |> Json.decodeString (Json.map toString errorDecoder)
            in
                case decodedError of
                    Result.Ok errorMsg ->
                        -- response.status.message ++ ": " ++ errorMsg
                        errorMsg

                    Result.Err _ ->
                        response.status.message

        _ ->
            toString error


errorDecoder =
    field "errors" Json.value



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [] [ text "elm-jwt with Phoenix backend" ]
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
                        [ label
                            [ for "uname" ]
                            [ text "Username" ]
                        , input
                            -- [ on "input" (Json.map (Input Uname) targetValue) (Signal.message address)
                            [ onInput (FormInput Uname)
                            , class "form-control"
                            , value model.uname
                            ]
                            []
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
                    token =
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
                            , onClick TryInvalidToken
                            ]
                            [ text "Try invalid token" ]
                        , button
                            [ class "btn btn-warning"
                            , onClick TryErrorRoute
                            ]
                            [ text "Try api route with error" ]
                        , p [] [ text "Wait 30 seconds and try again too" ]
                        ]
        , p
            [ style [ ( "color", "red" ) ] ]
            [ text model.msg ]
        ]



-- COMMANDS


submitCredentials : Model -> Cmd Msg
submitCredentials model =
    E.object
        [ ( "username", E.string model.uname )
        , ( "password", E.string model.pword )
        ]
        |> authenticate authUrl tokenStringDecoder
        |> Http.send Auth


tryToken : String -> Cmd Msg
tryToken token =
    Jwt.get token "/api/data" dataDecoder
        |> Jwt.sendCheckExpired token GetResult


tryErrorRoute : String -> Cmd Msg
tryErrorRoute token =
    Jwt.get token "/api/data_error" dataDecoder
        |> Jwt.send ErrorRouteResult
