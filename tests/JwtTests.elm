module JwtTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Jwt exposing (..)
import Json.Decode as Decode


suite : Test
suite =
    describe "decoding"
        [ test "decodeToken works with valid token" <|
            \_ ->
                decodeToken jwt1Decoder jwt1
                    |> Expect.equal (Ok expJwt1)
        , test "decodeToken should fail when signature invalid" <|
            \_ ->
                decodeToken jwt1Decoder "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5cXXX"
                    |> Expect.equal (Ok expJwt1)

        -- , test "tokenDecoder works with valid token" <|
        --     \_ ->
        --         decodeToken jwt1Decoder jwt1
        --             |> Expect.equal (Ok expJwt1)
        -- , test "decodes valid token body" <|
        --     \_ ->
        --         getTokenHeader jwt1
        --             |> Decode.decodeString jwt1HeaderDecoder
        --             |> Expect.equal (Ok ( "HS256", "JWT" ))
        ]


jwt1 =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"


type alias Jwt1 =
    { sub : String
    , name : String
    , iat : Int
    }


jwt1HeaderDecoder =
    Decode.map2 (,)
        (Decode.field "alg" Decode.string)
        (Decode.field "typ" Decode.string)


jwt1Decoder : Decode.Decoder Jwt1
jwt1Decoder =
    Decode.map3 Jwt1
        (Decode.field "sub" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "iat" Decode.int)


expJwt1 =
    Jwt1 "1234567890" "John Doe" 1516239022
