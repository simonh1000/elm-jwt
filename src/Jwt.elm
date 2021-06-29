module Jwt exposing
    ( decodeToken, tokenDecoder, checkTokenExpiry, getTokenExpirationMillis, isExpired, getTokenHeader
    , JwtError(..), errorToString
    )

{-| Helper functions for working with Jwt tokens


# Token reading

@docs decodeToken, tokenDecoder, checkTokenExpiry, getTokenExpirationMillis, isExpired, getTokenHeader


# Errors

@docs JwtError, errorToString

-}

import Base64
import Json.Decode as Decode exposing (Decoder, Value, field)
import String
import Task exposing (Task)
import Time exposing (Posix)



-- TOKEN PROCESSING


{-| Parses the token, checking that it meets the Jwt standards. In the event of success, `decodeToken` returns result of the JSON Decoder.

    decodeToken dec token

-}
decodeToken : Decoder a -> String -> Result JwtError a
decodeToken dec token =
    token
        |> getTokenParts
        |> Result.map Tuple.second
        |> Result.andThen (Decode.decodeString dec >> Result.mapError TokenDecodeError)


{-| All the token parsing goodness in the form of a Json Decoder

    firebaseToken =
        Json.Decode.decodeString (tokenDecoder Jwt.Decoders.firebase) tokenString

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


{-| Checks a token for Expiry (used the "exp" field). Returns expiry or any error that occurred in processing.
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


{-| Checks whether a token has expired, and returns True or False, or
any error that occurred while processing the token.
-}
isExpired : Posix -> String -> Result JwtError Bool
isExpired now token =
    getTokenExpirationMillis token
        |> Result.map (\millis -> Time.posixToMillis now > millis)


{-| Extracts the token expiration timestamp from the JWT "exp" field.
Returns the timestamp in milliseconds since epoch, or any error that
occurred while processing the token.
-}
getTokenExpirationMillis : String -> Result JwtError Int
getTokenExpirationMillis token =
    let
        decodeExp =
            Decode.oneOf [ Decode.int, Decode.map round Decode.float ]
    in
    decodeToken (field "exp" decodeExp) token
        |> Result.map (\exp -> 1000 * exp)


{-| Returns stringified json of the token's header
-}
getTokenHeader : String -> Result JwtError String
getTokenHeader =
    getTokenParts >> Result.map Tuple.first



-- ------------------------
-- Private token processing functions
-- ------------------------


{-| Fully processes token into header and body json strings, and tests that both are vaild json
-}
getTokenParts : String -> Result JwtError ( String, String )
getTokenParts token =
    let
        processor =
            unurl >> String.split "." >> List.map fixlength

        verifyJson : (Decode.Error -> JwtError) -> String -> Result JwtError String
        verifyJson errorHandler str =
            Decode.decodeString Decode.value str
                |> Result.map (\_ -> str)
                |> Result.mapError errorHandler
    in
    case processor token of
        [ Ok header, Ok body, _ ] ->
            let
                header_ =
                    Base64.toString header
                        |> Result.fromMaybe TokenHeaderError
                        |> Result.andThen (verifyJson (\_ -> TokenHeaderError))

                body_ =
                    Base64.toString body
                        |> Result.fromMaybe (TokenProcessingError "Invalid UTF-16")
                        |> Result.andThen (verifyJson TokenDecodeError)
            in
            Result.map2 (\a b -> ( a, b )) header_ body_

        [ _, Err err, _ ] ->
            Err err

        [ Err err, _, _ ] ->
            Err err

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



-- ------------------
-- ERRORS
-- ------------------


{-| The following errors are modeled

  - `TokenProcessingError` - something wrong with the the raw token (e.g. length, base64 encoding)
  - `TokenDecodeError` - the token is not valid JSON or the decoder provided could not decode the body
  - `TokenHeaderError` - the header is corrupted in some way

-}
type JwtError
    = TokenProcessingError String
    | TokenDecodeError Decode.Error
    | TokenHeaderError


{-| Provides a default conversion of a JwtError to a string
-}
errorToString : JwtError -> String
errorToString jwtErr =
    case jwtErr of
        TokenProcessingError err ->
            "JWT Token Processing error: " ++ err

        TokenDecodeError err ->
            "JWT Token Decoding error: " ++ Decode.errorToString err

        TokenHeaderError ->
            "JWT Token Header is corrupted"
