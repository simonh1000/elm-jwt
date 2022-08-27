module Decoders exposing (..)

import Json.Decode exposing (Decoder, Value, field, int, map4, oneOf, string)


type alias JwtToken =
    { id : String
    , username : String
    , iat : Int
    , expiry : Int
    }


tokenStringDecoder =
    field "token" string


dataDecoder =
    field "data" string


tokenDecoder : Decoder JwtToken
tokenDecoder =
    oneOf
        [ nodeDecoder
        , phoenixDecoder
        ]


nodeDecoder : Decoder JwtToken
nodeDecoder =
    map4 JwtToken
        (field "id" string)
        (field "username" string)
        (field "iat" int)
        (field "exp" int)


phoenixDecoder =
    map4 JwtToken
        (field "aud" string)
        (field "aud" string)
        (field "iat" int)
        (field "exp" int)
