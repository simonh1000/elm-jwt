module Jwt.Decoders exposing (JwtToken, firebase, phoenixGuardian)

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Decoders for popular Jwt tokens

@docs JwtToken, firebase, phoenixGuardian

-}

import Json.Decode as Decode exposing (Decoder, field)


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
    Decode.succeed JwtToken
        |> andMap (field "iat" Decode.int)
        |> andMap (field "exp" Decode.int)
        |> andMap (Decode.maybe <| field "user_id" Decode.string)
        |> andMap (Decode.maybe <| field "email" Decode.string)


{-| Decoder for Guardian
<https://github.com/ueberauth/guardian>
-}
phoenixGuardian : Decoder JwtToken
phoenixGuardian =
    Decode.succeed JwtToken
        |> andMap (field "iat" Decode.int)
        |> andMap (field "exp" Decode.int)
        |> andMap (Decode.succeed Nothing)
        |> andMap (Decode.succeed Nothing)



-- Helpers


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
