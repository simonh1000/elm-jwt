module Decoders exposing (..)

import Json.Decode as Json exposing (Decoder, Value, field, int, map4, oneOf, string, succeed)


type alias JwtToken =
    { id : String
    , username : String
    , iat : Int
    , expiry : Int
    }


tokenStringDecoder =
    field "token" string


dataDecoder : Decoder String
dataDecoder =
    field "data" string


data2Decoder : Decoder String
data2Decoder =
    succeed "success"


tokenDecoder =
    oneOf
        [ nodeDecoder
        , phoenixDecoder
        ]


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
