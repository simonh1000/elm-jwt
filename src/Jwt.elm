module Jwt exposing
    ( decodeToken, tokenDecoder, isExpired, checkTokenExpiry
    , JwtError(..), stringFromJwtError
    )

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Token reading

@docs decodeToken, tokenDecoder, isExpired, checkTokenExpiry


# Authenticated Http requests

@docs createRequest, createRequestObject, send, sendCheckExpired, get, post, put, delete


# Errors

@docs JwtError, stringFromJwtError

-}

import Base64
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
    = TokenExpired
    | TokenNotExpired
    | TokenProcessingError String
    | TokenDecodeError Decode.Error
    | Unauthorized -- unused


stringFromJwtError : JwtError -> String
stringFromJwtError jwtErr =
    case jwtErr of
        Unauthorized ->
            "Unauthorized"

        TokenExpired ->
            "Token expired"

        TokenNotExpired ->
            "Insufficient priviledges"

        TokenProcessingError err ->
            "Processing error: " ++ err

        TokenDecodeError err ->
            "Decoding error: " ++ Decode.errorToString err



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
                        Decode.fail <| stringFromJwtError err
            )



-- Private helper functions


getTokenBody : String -> Result JwtError String
getTokenBody =
    getTokenParts >> Result.map Tuple.second


getTokenHeader : String -> Result JwtError String
getTokenHeader =
    getTokenParts >> Result.map Tuple.first


getTokenParts : String -> Result JwtError ( String, String )
getTokenParts token =
    let
        processor =
            unurl >> String.split "." >> List.map fixlength
    in
    case processor token of
        [ Ok header, Ok encBody, _ ] ->
            Ok ( header, encBody )

        [ _, Err e, _ ] ->
            Err e

        [ Err e, _, _ ] ->
            Err e

        _ ->
            Err <| TokenProcessingError "Token has invalid shape"


{-| -}
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
            Ok s

        2 ->
            Ok <| String.concat [ s, "==" ]

        3 ->
            Ok <| String.concat [ s, "=" ]

        _ ->
            Err <| TokenProcessingError "Wrong length"


{-| Checks a token for Expiry. Returns expiry or any errors that occurred in decoding.
-}
checkTokenExpiry : String -> Task Never JwtError
checkTokenExpiry token =
    Time.now
        |> Task.andThen (checkUnacceptedToken token >> Task.succeed)


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
