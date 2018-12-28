module Jwt.Http exposing (delete, get, is401, post, put)

{-
   # Authenticated Http requests

   @docs get, post, put, delete, is401
-}

import Http exposing (Expect, expectJson, header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder, Value, field)
import Jwt exposing (..)
import Task exposing (Task)
import Time exposing (Posix)



{- ====================================================
    MAKING AUTHENTICATED API CALLS
   ====================================================
-}


{-| `get` is a replacement for `Http.get` that also takes a token, which is attached to the headers.

    getData : String -> Cmd Msg
    getData token =
        JHttp.get token
            { url = serverUrl ++ "/api/data"
            , expect = Http.expectJson OnDataResponse dataDecoder
            }

-}
get : String -> { url : String, expect : Expect msg } -> Cmd msg
get token { url, expect } =
    createRequest "GET"
        token
        { url = url
        , expect = expect
        , body = Http.emptyBody
        }


{-| post is a replacement for `Http.post` that also takes a token, which is attached to the headers.

    NOTE that is important to use jsonBody to ensure that the 'application/json' is added to the headers

    postContent : Token -> String -> Decoder a -> Encode.Value -> Cmd msg
    postContent token url dec value =
        post token
            { url = url
            , body = Http.jsonBody value
            , expect = Http.expectJson ContentResult (phoenixDecoder dec)
            }

-}
post : String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
post =
    createRequest "POST"


{-| Create a PUT request with a token attached to the Authorization header
-}
put : String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
put =
    createRequest "PUT"


{-| returns a `DELETE` Http.Request with the token attached to the headers.
-}
delete : String -> { url : String, expect : Expect msg } -> Cmd msg
delete token { url, expect } =
    createRequest "DELETE"
        token
        { url = url
        , expect = expect
        , body = Http.emptyBody
        }


{-| createRequest creates the data structure expected by Http.Request.
It is broken out here so that users can change the expect part in the event that
one of their REST apis does not return Json.

In my experience, the Authorization header is NOT case sensitive. Do raise an issue if you experience otherwise.

See [MDN](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/withCredentials) for more on withCredentials. The default is False.

-}
createRequest : String -> String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
createRequest method token { url, body, expect } =
    let
        options =
            { method = method
            , headers = [ header "Authorization" ("Bearer " ++ token) ]
            , url = url
            , body = body
            , expect = expect
            , timeout = Nothing
            , tracker = Nothing
            }
    in
    request options


{-| Helper that checks for a 401 in an Http error
-}
is401 : Http.Error -> Bool
is401 err =
    case err of
        Http.BadStatus 401 ->
            True

        _ ->
            False
