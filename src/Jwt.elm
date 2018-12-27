module Jwt exposing
    ( decodeToken, tokenDecoder, isExpired, checkTokenExpiry, checkToken
    , JwtError(..), errorToString
    , getTokenHeader
    )

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Token reading

@docs decodeToken, tokenDecoder, isExpired, checkTokenExpiry, checkToken


# Authenticated Http requests

@docs createRequest, createRequestObject, send, sendCheckExpired, get, post, put, delete


# Errors

@docs JwtError, errorToString

-}

import Base64
import Json.Decode as Decode exposing (Decoder, Value, field)
import String
import Task exposing (Task)
import Time exposing (Posix)


{-| The following errors are modeled

  - TokenProcessingError - something wrong with the the token (e.g. length, encoding)
  - TokenDecodeError - the decoder provided could not decode the body of the TokenNotExpired
  - TokenHeaderError - the header is corrupted in some way

-}
type JwtError
    = TokenProcessingError String
    | TokenDecodeError Decode.Error
    | TokenHeaderError


errorToString : JwtError -> String
errorToString jwtErr =
    case jwtErr of
        TokenProcessingError err ->
            "Processing error: " ++ err

        TokenDecodeError err ->
            "Decoding error: " ++ Decode.errorToString err

        TokenHeaderError ->
            "Header is corrupted"



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


{-| Returns a stringified json of the token's header
-}
getTokenHeader : String -> Result JwtError String
getTokenHeader token =
    token
        |> getTokenParts
        |> Result.map Tuple.first
        |> Result.andThen (Base64.decode >> Result.mapError TokenProcessingError)


checkTokenHeader : String -> Result JwtError Value
checkTokenHeader token =
    getTokenHeader token
        |> Result.andThen (Decode.decodeString Decode.value >> Result.mapError (\_ -> TokenHeaderError))



-- ------------------------
-- Private helper functions
-- ------------------------


getTokenBody : String -> Result JwtError String
getTokenBody =
    getTokenParts >> Result.map Tuple.second


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


{-| Checks a token for Expiry. Returns expiry or any error that occurred in decoding.
-}
checkTokenExpiry : String -> Task JwtError Bool
checkTokenExpiry token =
    Time.now
        |> Task.andThen
            (\now ->
                case isExpired now token of
                    Ok bool ->
                        Task.succeed bool

                    Err err ->
                        Task.fail err
            )


{-| Does a complete check of your token
-}
checkToken : String -> Task JwtError Bool
checkToken token =
    Time.now
        |> Task.andThen
            (\now ->
                case Result.map2 (\a b -> ( a, b )) (isExpired now token) (checkTokenHeader token) of
                    Ok ( bool, _ ) ->
                        Task.succeed bool

                    Err err ->
                        Task.fail err
            )


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
