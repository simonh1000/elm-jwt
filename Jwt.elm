module Jwt exposing
    ( JwtError(..)
    , authenticate, decodeToken
    , createRequest, get, get_, post, put
    , isExpired, promote401)

{-| Helper functions for Jwt tokens.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.

# Token reading
@docs decodeToken, isExpired

# Authenticated Http requests
@docs authenticate, createRequest, get, get_, post, put, promote401

# Errors
@docs JwtError
-}
import Http exposing (request, send, emptyBody, header, expectJson, jsonBody, toTask, Request)
import Task exposing (Task)
import Base64
import String
import Time exposing (Time)
import Json.Decode as Json exposing (field, Value)

{-| We distinguish between various errors
 - From Http.Error. We pass these straight through unless using `promote401`,
 - 401 (Unauthorized) errors, due either to token expiry or some other reason
 - issues with processing (e.g. base 64 decoding) the token, and
 - problems decoding the json data within the content of the token
-}
type JwtError
    = HttpError Http.Error
    | TokenExpired
    | TokenNotAccepted
    | TokenProcessingError String
    | TokenDecodeError String


-- TOKEN PROCESSING

type alias Token = String

{-| decodeToken parses the token, checking that it meets the Jwt standards.

    decodeToken dec token

In the event of success, `decodeToken` returns an Elm record structure using the JSON Decoder.
-}
decodeToken : Json.Decoder a -> Token -> Result JwtError a
decodeToken dec token =
    let
        f1 = String.split "." <| unurl token
        f2 = List.map fixlength f1
    in
    case f2 of
        (_ :: Result.Err e :: _ :: []) ->
            Result.Err e
        (_ :: Result.Ok encBody :: _ :: []) ->
            case Base64.decode encBody of
                Result.Ok body ->
                    case Json.decodeString dec body of
                        Result.Ok x -> Result.Ok x
                        Result.Err e -> Result.Err (TokenDecodeError e)
                Result.Err e -> Result.Err (TokenProcessingError e)
        _ -> Result.Err <| TokenProcessingError "Token has invalid shape"

-- Private functions
unurl : String -> String
unurl =
    let fix c =
        case c of
            '-' -> '+'
            '_' -> '/'
            c   -> c
    in String.map fix

fixlength : String -> Result JwtError String
fixlength s =
        case String.length s % 4 of
            0 ->
                Result.Ok s
            2 ->
                Result.Ok <| String.concat [s, "=="]
            3 ->
                Result.Ok <| String.concat [s, "="]
            _ ->
                Result.Err <| TokenProcessingError "Wrong length"

{-| `Checks whether a token has expired, and returns True or False, or
any error that occurred while decoding the token.

Note: This function assumes that the expiry was set in seconds and thus
multiplies by 1000 to compare with Javascript time (in milliseconds).
You may need to write a custom version if your server-side Jwt library works differently.
-}
isExpired : Time -> Token -> Result JwtError Bool
isExpired now token =
    decodeToken (field "exp" Json.float) token
    |> Result.map (\exp -> now > exp * 1000)


-- AUTHENTICATED HTTP REQUESTS

{-| `authenticate` is a standard Http POST method containing login credentials, and using
a json decoder to extract the returned token.

    submitCredentials : Model -> Cmd Msg
    submitCredentials model =
        E.object
            [ ("username", E.string model.uname)
            , ("password", E.string model.pword)
            ]
        |> authenticate Auth "/sessions" tokenStringDecoder
-}
authenticate : (Result Http.Error a -> msg) -> String -> Json.Decoder a -> Value -> Cmd msg
authenticate msgCreator url dec credentials =
    Http.post url (jsonBody credentials) dec
    |> send msgCreator


{-| createRequest creates a Http.Request with the token added to the headers, and
sets the `withCredentials` field to True.
-}
createRequest : String -> Token -> String -> Json.Decoder a -> Http.Body -> Request a
createRequest method token url dec body =
    request
        { method = method
        , headers =
            [ header "Content-type" "application/json"
            , header "Authorization" ("Bearer " ++ token)
            ]
        , url = url
        , body = body
        , expect = expectJson dec
        , timeout = Nothing
        , withCredentials = True
        }

{-| `get` is a replacement for `Http.get` that returns a Http.Request with the token
attached the headers.

    Task.perform
        PostFail PostSucess
        (get token dataDecoder "/api/data")
-}
get : Token -> String -> Json.Decoder a -> Request a
get token url dec =
    createRequest "GET" token url dec Http.emptyBody

{-| `get_` takes the same parameters as `get`, but returns a `Task` where a 401 Unauthorized error
due to token expiry has been converted into a `TokenExpired`.

    update ... =
    GetResult (Result.Err err) ->
        case err of
            Jwt.TokenExpired ->
                { model | msg = "Token expired" } ! []
            _ ->
                { model | msg = toString err } ! []

    [...]
    tryToken : String -> Cmd Msg
    tryToken token =
        Jwt.get_ token "/api/data" dataDecoder
        |> Task.perform GetResult
-}
get_ : Token -> String -> Json.Decoder a -> Task Never (Result JwtError a)
get_ token url dec =
    createRequest "GET" token url dec Http.emptyBody
    |> toTask
    |> Task.map Result.Ok
    |> Task.onError (promote401 token)

{-| post is a replacement for `Http.post` that attaches a provided Jwt token
to the headers.
-}
post : (Result Http.Error a -> msg) -> Token -> Json.Decoder a -> String -> Http.Body -> Cmd msg
post msgCreator token dec url body =
    createRequest "POST" token url dec body
    |> send msgCreator

{-| `put` provides `Http.put` with the token attached to the headers.
-}
put : (Result Http.Error a -> msg) -> Token -> Json.Decoder a -> String -> Http.Body -> Cmd msg
put msgCreator token dec url body =
    createRequest "PUT" token url dec body
    |> send msgCreator

{-| Examines a 401 Unauthorized reponse, and converts the error to TokenExpired
when that is the case.

    getAuth : Token -> String -> Json.Decoder a -> Task Never (Result JwtError a)
    getAuth token url dec =
        createRequest "GET" token url dec Http.emptyBody
        |> toTask
        |> Task.map Result.Ok
        |> Task.onError (promote401 token)
-}
promote401 : Token -> Http.Error -> Task Never (Result JwtError a)
promote401 token err =
    let defaultError = Task.succeed <| Result.Err (HttpError err)
    in
    case err of
        Http.BadStatus {status} ->
            if status.code == 401 then
                Time.now
                |> Task.andThen
                    (\t ->
                        case isExpired t token of
                            Result.Ok True ->
                                Task.succeed <| Result.Err TokenExpired
                            Result.Ok False ->
                                -- Although the token is not expired, server rejected request for some other reason
                                Task.succeed <| Result.Err TokenNotAccepted
                            Result.Err e ->
                                Task.succeed <| Result.Err e)
            else
                defaultError
        _ ->
            defaultError
