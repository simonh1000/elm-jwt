module Jwt.Decoders exposing (JwtToken, firebase, phoenixGuardian)

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Decoders for popular Jwt tokens

@docs JwtToken, firebase, phoenixGuardian

-}

import Json.Decode as Json exposing (Decoder, field)


{-| Generic constructor for commonly found fields in a Jwt token
-}
type alias JwtToken =
    { iat : Int
    , exp : Int
    , userId : Maybe String
    , email : Maybe String
    }


{-| Decoder for Firebase Jwt
-}
firebase : Decoder JwtToken
firebase =
    Json.succeed JwtToken
        |> andMap (field "iat" Json.int)
        |> andMap (field "exp" Json.int)
        |> andMap (Json.maybe <| field "user_id" Json.string)
        |> andMap (Json.maybe <| field "email" Json.string)


{-| Decoder for Guardian
<https://github.com/ueberauth/guardian>
-}
phoenixGuardian : Decoder JwtToken
phoenixGuardian =
    Json.succeed JwtToken
        |> andMap (field "iat" Json.int)
        |> andMap (field "exp" Json.int)
        |> andMap (Json.succeed Nothing)
        |> andMap (Json.succeed Nothing)



-- Helpers


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Json.map2 (|>)
