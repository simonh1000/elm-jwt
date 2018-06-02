module App exposing (Model, Msg, init, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Http
import Json.Encode as E exposing (Value)
import Json.Decode as Json exposing (field)
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


init : Browser.Env flags -> ( Model, Cmd Msg )
init _ =
    ( Model "testuser" "testpassword" Nothing "", Cmd.none )



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
    case Debug.log "update" message of
        FormInput inputId val ->
            case inputId of
                Uname ->
                    ( { model | uname = val }, Cmd.none )

                Pword ->
                    ( { model | pword = val }, Cmd.none )

        Login ->
            ( model, submitCredentials model )

        TryToken ->
            ( { model | msg = "Contacting server..." }
            , model.token
                |> Maybe.map tryToken
                |> Maybe.withDefault Cmd.none
            )

        TryInvalidToken ->
            ( { model | msg = "Contacting server..." }, tryToken "invalid token" )

        TryErrorRoute ->
            ( { model | msg = "Contacting server..." }
            , model.token
                |> Maybe.map tryErrorRoute
                |> Maybe.withDefault Cmd.none
            )

        Auth res ->
            case res of
                Result.Ok token ->
                    ( { model | token = Just token, msg = "" }, Cmd.none )

                Result.Err err ->
                    ( { model | msg = handleHttpError err }, Cmd.none )

        GetResult res ->
            case res of
                Ok msg ->
                    ( { model | msg = msg }, Cmd.none )

                Err jwtErr ->
                    failHandler_ ServerFail_ jwtErr model

        ErrorRouteResult res ->
            case res of
                Ok r ->
                    ( { model | msg = r }, Cmd.none )

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
            ( { model | msg = Debug.toString jwtErr }, Cmd.none )



-- We recurse at most once because Jwt.checkTokenExpirey cannot return Jwt.Unauthorized


failHandler : (JwtError -> msg) -> String -> JwtError -> { model | msg : String } -> ( { model | msg : String }, Cmd msg )
failHandler msgCreator token jwtErr model =
    case jwtErr of
        Jwt.Unauthorized ->
            ( { model | msg = "Unauthorized" }
            , Jwt.checkTokenExpiry token
                |> Task.perform msgCreator
            )

        Jwt.TokenExpired ->
            ( { model | msg = "Token expired" }, Cmd.none )

        Jwt.TokenNotExpired ->
            ( { model | msg = "Insufficient priviledges" }, Cmd.none )

        Jwt.HttpError err ->
            ( { model | msg = handleHttpError err }, Cmd.none )

        _ ->
            ( { model | msg = jwtErrorToString jwtErr }, Cmd.none )


handleHttpError : Http.Error -> String
handleHttpError error =
    case error of
        Http.BadStatus response ->
            let
                decodedError =
                    Json.decodeString errorDecoder response.body
            in
                case decodedError of
                    Result.Ok errorMsg ->
                        -- response.status.message ++ ": " ++ errorMsg
                        "todo errorMsg"

                    Result.Err _ ->
                        response.status.message

        Http.BadPayload s _ ->
            "payload" ++ s

        _ ->
            Debug.toString error


errorDecoder : Json.Decoder Json.Value
errorDecoder =
    field "errors" Json.value


jwtErrorToString : JwtError -> String
jwtErrorToString jwtError =
    Debug.toString jwtError



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
                        [ label [ for "uname" ] [ text "Username" ]
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
                    token =
                        case decodeToken Decoders.tokenDecoder tokenString of
                            Ok t ->
                                Debug.toString t

                            Err err ->
                                jwtErrorToString err
                in
                    div []
                        [ p [] [ text token ]
                        , mkButton TryToken "Try token"
                        , mkButton TryInvalidToken "Try invalid token"
                        , mkButton TryErrorRoute "Try api route with error"
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


serverUrl =
    "http://localhost:5000"


submitCredentials : Model -> Cmd Msg
submitCredentials model =
    let
        creds =
            [ ( "username", E.string model.uname )
            , ( "password", E.string model.pword )
            ]
                |> E.object
                |> Http.jsonBody
    in
        Http.post (serverUrl ++ "/sessions") creds tokenStringDecoder
            |> Http.send Auth


tryToken : String -> Cmd Msg
tryToken token =
    Jwt.get token (serverUrl ++ "/api/data") dataDecoder
        |> Jwt.sendCheckExpired token GetResult


tryErrorRoute : String -> Cmd Msg
tryErrorRoute token =
    Jwt.get token (serverUrl ++ "/api/data_error") dataDecoder
        |> Jwt.send ErrorRouteResult
