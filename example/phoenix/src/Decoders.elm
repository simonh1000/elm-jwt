module Decoders exposing (..)

import Json.Decode as Json exposing ( (:=), Value )

type alias JwtToken =
    { id: String
    , username : String
    , iat : Int
    , expiry : Int
    }

tokenDecoder =
    Json.oneOf
        [ nodeDecoder
        , phoenixDecoder
        ]

nodeDecoder =
    Json.object4 JwtToken
        ("id" := Json.string)
        ("username" := Json.string)
        ("iat" := Json.int)
        ("exp" := Json.int)

-- PHOENIX

phoenixDecoder =
    Json.object4 JwtToken
        ("aud" := Json.string)
        ("aud" := Json.string)
        ("iat" := Json.int)
        ("exp" := Json.int)
