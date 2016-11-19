module Jwt
    exposing
        ( JwtError(..)
        , decodeToken
        , isExpired
        , createRequest
        , authenticate
        , send
        , sendCheckExpired
        , get
        , post
        , put
        , delete
        , promote401
        , handleError
        , checkTokenExpirey
        )

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.

# Token reading
@docs decodeToken, isExpired

# Authenticated Http requests
@docs createRequest, send, sendCheckExpired, get, post, put, delete

# `JwtError`s and Http.Error handling
@docs JwtError, promote401, handleError, checkTokenExpirey

# Logging in
@docs authenticate
-}

import Http exposing (request, send, emptyBody, header, expectJson, jsonBody, toTask, Request)
import Task exposing (Task)
import Base64
import String
import Time exposing (Time)
import Json.Decode as Json exposing (field, Value)


{-| The following errors are modeled
 - Any Http.Error, other than a 401
 - 401 (Unauthorized), due either to token expiry or e.g. inadequate permissions
 - issues with processing (e.g. base 64 decoding) the token, and
 - problems decoding the json data within the content of the token
-}
type JwtError
    = HttpError Http.Error
    | Unauthorized
    | TokenExpired
    | TokenNotExpired
    | TokenProcessingError String
    | TokenDecodeError String



-- TOKEN PROCESSING


{-| decodeToken parses the token, checking that it meets the Jwt standards.

    decodeToken dec token

In the event of success, `decodeToken` returns an Elm record structure using the JSON Decoder.
-}
decodeToken : Json.Decoder a -> String -> Result JwtError a
decodeToken dec token =
    let
        f1 =
            String.split "." <| unurl token

        f2 =
            List.map fixlength f1
    in
        case f2 of
            _ :: (Result.Err e) :: _ :: [] ->
                Result.Err e

            _ :: (Result.Ok encBody) :: _ :: [] ->
                case Base64.decode encBody of
                    Result.Ok body ->
                        case Json.decodeString dec body of
                            Result.Ok x ->
                                Result.Ok x

                            Result.Err e ->
                                Result.Err (TokenDecodeError e)

                    Result.Err e ->
                        Result.Err (TokenProcessingError e)

            _ ->
                Result.Err <| TokenProcessingError "Token has invalid shape"


{-| Checks whether a token has expired, and returns True or False, or
any error that occurred while decoding the token.

Note: This function assumes that the expiry was set in seconds and thus
multiplies by 1000 to compare with Javascript time (in milliseconds).
You may need to write a custom version if your server-side Jwt library works differently.
-}
isExpired : Time -> String -> Result JwtError Bool
isExpired now token =
    decodeToken (field "exp" Json.float) token
        |> Result.map (\exp -> now > exp * 1000)



-- Private functions


unurl : String -> String
unurl =
    let
        fix c =
            case c of
                '-' ->
                    '+'

                '_' ->
                    '/'

                c ->
                    c
    in
        String.map fix


fixlength : String -> Result JwtError String
fixlength s =
    case String.length s % 4 of
        0 ->
            Result.Ok s

        2 ->
            Result.Ok <| String.concat [ s, "==" ]

        3 ->
            Result.Ok <| String.concat [ s, "=" ]

        _ ->
            Result.Err <| TokenProcessingError "Wrong length"



{- ====================================================
    LOGGING IN - GETTING A TOKEN
   ====================================================
-}


{-| `authenticate` creates an Http.Request based on login credentials.

    submitCredentials : Model -> Cmd Msg
    submitCredentials model =
        E.object
            [ ("username", E.string model.uname)
            , ("password", E.string model.pword)
            ]
        |> authenticateRequest "/sessions" tokenStringDecoder
-}
authenticate : String -> Json.Decoder a -> Value -> Request a
authenticate url dec credentials =
    Http.post url (jsonBody credentials) dec



{- ====================================================
    MAKING AUTHENTICATED API CALLS
   ====================================================
-}


{-| createRequest creates a Http.Request with the token added to the headers, and
sets the `withCredentials` field to True.
-}
createRequest : String -> String -> String -> Http.Body -> Json.Decoder a -> Request a
createRequest method token url body dec =
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


{-| `send` replaces `Http.send`. On receipt of a 401 error, it returns a Jwt.Unauthorized.
-}
send : (Result JwtError a -> msg) -> Request a -> Cmd msg
send msgCreator =
    Http.send (conv msgCreator)


conv : (Result JwtError a -> msg) -> (Result Http.Error a -> msg)
conv fn =
    -- \res ->
    --     fn (Result.mapError promote401 res)
    fn << Result.mapError promote401


{-| `sendCheckExpired` is similar to `send` but, on receiving a 401, it carries out a further check to
determine whether the token has expired.
-}
sendCheckExpired : String -> (Result JwtError a -> msg) -> Request a -> Cmd msg
sendCheckExpired token msgCreator request =
    request
        |> toTask
        |> Task.map Result.Ok
        |> Task.onError (Task.map Err << handleError token)
        |> Task.perform msgCreator


{-| `get` is a replacement for `Http.get` that returns a Http.Request with the token
attached to the headers.

    getData : String -> Cmd Msg
    getData token =
        Jwt.get token "/api/data" dataDecoder
            |> Jwt.send DataResult
-}
get : String -> String -> Json.Decoder a -> Request a
get token url dec =
    createRequest "GET" token url Http.emptyBody dec


{-| post is a replacement for `Http.post` that returns a Http.Request with the token
attached to the headers.
-}
post : String -> String -> Http.Body -> Json.Decoder a -> Request a
post =
    createRequest "POST"


{-| `put` returns a PUT Http.Request with the token attached to the headers.
-}
put : String -> String -> Http.Body -> Json.Decoder a -> Request a
put =
    createRequest "PUT"


{-| `delete` returns a DELETE Http.Request with the token attached to the headers.
-}
delete : String -> String -> Json.Decoder a -> Request a
delete token url dec =
    createRequest "DELETE" token url Http.emptyBody dec


{-| Examines a 401 Unauthorized reponse, and converts the error to TokenExpired
when that is the case.

    getAuth : String -> String -> Json.Decoder a -> Task Never (Result JwtError a)
    getAuth token url dec =
        createRequest "GET" token url Http.emptyBody dec
        |> toTask
        |> Task.map Result.Ok
        |> Task.onError (promote401 token)
-}
promote401 : Http.Error -> JwtError
promote401 err =
    case err of
        Http.BadStatus { status } ->
            if status.code == 401 then
                Unauthorized
            else
                HttpError err

        _ ->
            HttpError err


{-| Takes an Http.Error. If it is a 401 then it chekcs for expirey.
-}
handleError : String -> Http.Error -> Task Never JwtError
handleError token err =
    case promote401 err of
        Unauthorized ->
            checkTokenExpirey token

        _ ->
            Task.succeed (HttpError err)


{-| Checks a token for expirey.
-}
checkTokenExpirey : String -> Task Never JwtError
checkTokenExpirey token =
    Time.now
        |> Task.andThen (checkUnacceptedToken token >> Task.succeed)


checkUnacceptedToken : String -> Time -> JwtError
checkUnacceptedToken token now =
    case isExpired now token of
        Result.Ok True ->
            TokenExpired

        Result.Ok False ->
            -- Although the token is not expired, server rejected request for some other reason
            TokenNotExpired

        Result.Err jwtErr ->
            -- Pass through a decoding error
            jwtErr
