module Jwt exposing
    ( decodeToken, tokenDecoder, isExpired, checkTokenExpiry
    , JwtError(..), promote401, handleError
    )

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Token reading

@docs decodeToken, tokenDecoder, isExpired, checkTokenExpiry


# Authenticated Http requests

@docs createRequest, createRequestObject, send, sendCheckExpired, get, post, put, delete


# Error handlers

@docs JwtError, promote401, handleError

-}

import Base64
import Http exposing (expectJson, header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder, Value, field)
import String
import Task exposing (Task)
import Time exposing (Posix)


{-| The following errors are modeled

  - 401 (Unauthorized), due either to token expiry or e.g. inadequate permissions
  - token (non-)expiry information
  - issues with processing (e.g. base 64 decoding) the token
  - problems decoding the json data within the content of the token
  - Any Http.Error, other than a 401

-}
type JwtError
    = Unauthorized
    | TokenExpired
    | TokenNotExpired
    | TokenProcessingError String
    | TokenDecodeError Decode.Error
    | HttpError Http.Error


errorToString : JwtError -> String
errorToString jwtError =
    case jwtError of
        Unauthorized ->
            "Unauthorized"

        _ ->
            "some error"



-- TOKEN PROCESSING


{-| decodeToken parses the token, checking that it meets the Jwt standards.

    decodeToken dec token

In the event of success, `decodeToken` returns an Elm record structure using the JSON Decoder.

-}
decodeToken : Decoder a -> String -> Result JwtError a
decodeToken dec =
    getTokenBody
        >> Result.andThen (Base64.decode >> Result.mapError TokenProcessingError)
        >> Result.andThen (Decode.decodeString dec >> Result.mapError TokenDecodeError)


{-| All the token parsing goodness in the form of a Json Decoder

    -- decode token from Firebase
    let firebaseToken =
            decodeString (tokenDecoder Jwt.Decoders.firebase) tokenString

-}
tokenDecoder : Decoder a -> Decoder a
tokenDecoder dec =
    Decode.string
        |> Decode.andThen
            (\tokenStr ->
                case decodeToken dec tokenStr of
                    Ok val ->
                        Decode.succeed val

                    Err err ->
                        Decode.fail <| errorToString err
            )



-- Private helper functions


getTokenBody : String -> Result JwtError String
getTokenBody token =
    let
        processor =
            unurl >> String.split "." >> List.map fixlength
    in
    case processor token of
        _ :: (Result.Err e) :: _ :: [] ->
            Result.Err e

        _ :: (Result.Ok encBody) :: _ :: [] ->
            Result.Ok encBody

        _ ->
            Result.Err <| TokenProcessingError "Token has invalid shape"


unurl : String -> String
unurl =
    let
        fix c =
            case c of
                '-' ->
                    '+'

                '_' ->
                    '/'

                _ ->
                    c
    in
    String.map fix


fixlength : String -> Result JwtError String
fixlength s =
    case modBy 4 (String.length s) of
        0 ->
            Result.Ok s

        2 ->
            Result.Ok <| String.concat [ s, "==" ]

        3 ->
            Result.Ok <| String.concat [ s, "=" ]

        _ ->
            Result.Err <| TokenProcessingError "Wrong length"


{-| Checks a token for Expiry. Returns expiry or any errors that occurred in decoding.
-}
checkTokenExpiry : String -> Task Never JwtError
checkTokenExpiry token =
    Time.now
        |> Task.andThen (checkUnacceptedToken token >> Task.succeed)


{-| Checks whether a token has expired, and returns True or False, or
any error that occurred while decoding the token.
-}
isExpired : Posix -> String -> Result JwtError Bool
isExpired now token =
    decodeToken (field "exp" decodeExp) token
        |> Result.map (\exp -> Time.posixToMillis now > exp * 1000)


decodeExp : Decoder Int
decodeExp =
    Decode.oneOf [ Decode.int, Decode.map round Decode.float ]


checkUnacceptedToken : String -> Posix -> JwtError
checkUnacceptedToken token now =
    case isExpired now token of
        Ok True ->
            TokenExpired

        Ok False ->
            -- Although the token is not expired, server rejected request for some other reason
            TokenNotExpired

        Err jwtErr ->
            -- Pass through a decoding error
            jwtErr


{-| Takes an Http.Error. If it is a 401, check the token for expiry.
-}
handleError : String -> Http.Error -> Task Never JwtError
handleError token err =
    case promote401 err of
        Unauthorized ->
            checkTokenExpiry token

        other ->
            Task.succeed other


{-| Examines a 401 Unauthorized reponse, and converts the error to TokenExpired
when that is the case.

    getAuth : String -> String -> Decoder a -> Task Never (Result JwtError a)
    getAuth token url dec =
        createRequest "GET" token url Http.emptyBody dec
            |> toTask
            |> Task.map Result.Ok
            |> Task.onError (promote401 token)

-}
promote401 : Http.Error -> JwtError
promote401 err =
    case err of
        Http.BadStatus status ->
            if status == 401 then
                Unauthorized

            else
                HttpError err

        _ ->
            HttpError err
