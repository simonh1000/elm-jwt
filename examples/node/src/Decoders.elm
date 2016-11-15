module Decoders exposing (..)

import Json.Decode as Json exposing ( field, Value )

type alias JwtToken =
    { id: String
    , username : String
    , iat : Int
    , expiry : Int
    }

tokenStringDecoder =
  field "token" Json.string

dataDecoder =
  field "data" Json.string

tokenDecoder =
    Json.oneOf
        [ nodeDecoder
        , phoenixDecoder
        ]

nodeDecoder =
    Json.map4 JwtToken
        (field "id" Json.string)
        (field "username" Json.string)
        (field "iat" Json.int)
        (field "exp" Json.int)

-- PHOENIX

phoenixDecoder =
    Json.map4 JwtToken
        (field "aud" Json.string)
        (field "aud" Json.string)
        (field "iat" Json.int)
        (field "exp" Json.int)
