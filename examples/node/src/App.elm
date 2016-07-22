module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json exposing ((:=), Value)
import Json.Encode as E
import Task exposing (toResult)
import Jwt exposing (JwtError, authenticate, getWithJwt, decodeToken)


-- COMMANDS


authenticateCmd : String -> Cmd Msg
authenticateCmd credentials =
    (authenticate ("token" := Json.string) "http://localhost:5000/auth" credentials)
        |> Task.perform LoginFail LoginSuccess


authGetCmd : Maybe String -> Json.Decoder String -> String -> Cmd Msg
authGetCmd token decoder url =
    (getWithJwt (Maybe.withDefault "" token) decoder url)
        |> Task.perform PostFail PostSucess



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
    ( Model "testuser" "testpassword" Nothing "", Cmd.none )


type alias JwtToken =
    { id : String
    , username : String
    , iat : Int
    , expiry : Int
    }


tokenDecoder : Json.Decoder JwtToken
tokenDecoder =
    Json.object4 JwtToken
        ("id" := Json.string)
        ("username" := Json.string)
        ("iat" := Json.int)
        ("exp" := Json.int)



-- UPDATE


type
    Msg
    -- User generated Msg
    = FormInput Field String
    | Submit
    | TryToken
      -- Cmd results
    | LoginSuccess String
    | LoginFail JwtError
    | PostSucess String
    | PostFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FormInput inputId val ->
            let
                res =
                    case inputId of
                        Uname ->
                            { model | uname = val }

                        Pword ->
                            { model | pword = val }
            in
                ( res, Cmd.none )

        Submit ->
            let
                credentials =
                    E.object
                        [ ( "username", E.string model.uname )
                        , ( "password", E.string model.pword )
                        ]
                        |> E.encode 0
            in
                ( model, authenticateCmd credentials )

        TryToken ->
            ( model
            , authGetCmd model.token ("data" := Json.string) "http://localhost:5000/test"
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
        [ h1 [] [ text "elm-jwt with node backend" ]
        , p [] [ text "username = testuser, password = testpassword" ]
        , div
            [ class "row" ]
            [ Html.form
                [ onSubmit Submit
                , class "col s12"
                ]
                [ div
                    [ class "row" ]
                    [ div
                        [ class "input-field col s12" ]
                        [ input
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
        , p []
            [ text <|
                case model.token of
                    Nothing ->
                        ""

                    Just token ->
                        toString (decodeToken tokenDecoder token)
            ]
        , p [] [ text model.msg ]
        , button
            [ class "btn waves-effect waves-light"
            , onClick TryToken
            ]
            [ text "try token" ]
        ]



-- CMDS
