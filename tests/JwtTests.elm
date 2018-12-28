module JwtTests exposing (Jwt1, expJwt1, invalidHeader, jwt1Decoder, jwt1HeaderDecoder, suite, validToken)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode as Decode
import Jwt exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "decoding"
        [ test "decodeToken works with valid token" <|
            \_ ->
                decodeToken jwt1Decoder validToken
                    |> Expect.equal (Ok expJwt1)
        , test "decodeToken should fail when body invalid" <|
            \_ ->
                decodeToken jwt1Decoder invalidBody
                    |> Expect.equal (Err (TokenProcessingError "Invalid UTF-16"))
        , test "decodeToken should fail when header invalid" <|
            \_ ->
                decodeToken jwt1Decoder invalidHeader
                    |> Expect.equal (Err TokenHeaderError)
        , test "decodes valid token header" <|
            \_ ->
                getTokenHeader validToken
                    |> Result.andThen (Decode.decodeString jwt1HeaderDecoder >> Result.mapError TokenDecodeError)
                    |> Expect.equal (Ok ( "HS256", "JWT" ))
        , test "identifies an invalid token header" <|
            \_ ->
                getTokenHeader invalidHeader
                    |> Result.andThen (Decode.decodeString jwt1HeaderDecoder >> Result.mapError TokenDecodeError)
                    |> Expect.equal (Err TokenHeaderError)
        ]


validToken =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"


invalidBody =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxeyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"


invalidHeader =
    "xxeyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"


type alias Jwt1 =
    { sub : String
    , name : String
    , iat : Int
    }


jwt1HeaderDecoder =
    Decode.map2 (\a b -> ( a, b ))
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
