module Decoders exposing (..)

import Json.Decode as Json exposing ( map4, oneOf, field, int, string, Value )

type alias JwtToken =
    { id: String
    , username : String
    , iat : Int
    , expiry : Int
    }

tokenStringDecoder =
  field "token" <| string

dataDecoder =
  field "data" <| string

tokenDecoder =
    oneOf
        [ nodeDecoder
        , phoenixDecoder
        ]

nodeDecoder =
    map4 JwtToken
        (field "id" <| string)
        (field "username" <| string)
        (field "iat" <| int)
        (field "exp" <| int)

-- PHOENIX

phoenixDecoder =
    map4 JwtToken
        (field "aud" <| string)
        (field "aud" <| string)
        (field "iat" <| int)
        (field "exp" <| int)
