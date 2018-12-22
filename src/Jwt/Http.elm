module Jwt.Http exposing (get, post)

import Base64
import Http exposing (Expect, expectJson, header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder, Value, field)
import Jwt exposing (..)
import String
import Task exposing (Task)
import Time exposing (Posix)



{- ====================================================
    MAKING AUTHENTICATED API CALLS
   ====================================================
-}


{-| `get` is a replacement for `Http.get` that also takes a token, which is attached to the headers.

    getData : String -> Cmd Msg
    getData token =
        Jwt.get token "/api/data" dataDecoder
            |> Jwt.send DataResult

-}
get :
    String
    ->
        { url : String
        , expect : Expect msg
        }
    -> Cmd msg
get token { url, expect } =
    let
        options =
            { method = "GET"
            , headers = [ header "Authorization" ("Bearer " ++ token) ]
            , url = url
            , body = Http.emptyBody
            , expect = expect
            , timeout = Nothing
            , tracker = Nothing
            }
    in
    request options


{-| post is a replacement for `Http.post` that also takes a token, which is attached to the headers.

\*\* Note that is important to use jsonBody to ensure that the 'application/json' is added to the headers \*\*

    postContent : Token -> Decoder a -> E.Value -> String -> Request a
    postContent token dec value url =
        Jwt.post token url (Http.jsonBody value) (phoenixDecoder dec)
            |> Jwt.send ContentResult

-}
post :
    String
    ->
        { url : String
        , body : Http.Body
        , expect : Http.Expect msg
        }
    -> Cmd msg
post token { url, body, expect } =
    let
        options =
            { method = "POST"
            , headers = [ header "Authorization" ("Bearer " ++ token) ]
            , url = url
            , body = body
            , expect = expect
            , timeout = Nothing
            , tracker = Nothing
            }
    in
    request options



-- {-| Create a PUT request with a token attached to the Authorization header
-- -}
-- put : String -> String -> Http.Body -> Decoder a -> Request a
-- put =
--     createRequest "PUT"
--
--
-- {-| returns a `DELETE` Http.Request with the token attached to the headers.
-- -}
-- delete : String -> String -> Decoder a -> Request a
-- delete token url dec =
--     createRequest "DELETE" token url Http.emptyBody dec
--
--
--
-- {-| createRequest creates a Http.Request with the token added to the headers, and
-- sets the `withCredentials` field to True.
-- -}
-- createRequest : String -> String -> String -> Http.Body -> Decoder a -> Http.Request a
-- createRequest method token url body =
--     createRequestObject method token url body >> request
--
--
-- {-| createRequestObject creates the data structure expected by Http.Request.
-- It is broken out here so that users can change the expect part in the event that
-- one of their REST apis does not return Json.
--
-- In my experience, the Authorization header is NOT case sensitive. Do raise an issue if you experience otherwise.
--
-- See [MDN](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/withCredentials) for more on withCredentials. The default is False.
--
-- -}
-- createRequestObject :
--     String
--     -> String
--     -> String
--     -> Http.Body
--     -> Decoder a
--     -> { method : String, headers : List Http.Header, url : String, body : Http.Body, expect : Http.Expect a, timeout : Maybe Float, withCredentials : Bool }
-- createRequestObject method token url body dec =
--     { method = method
--     , headers = [ header "Authorization" ("Bearer " ++ token) ]
--     , url = url
--     , body = body
--     , expect = expectJson dec
--     , timeout = Nothing
--     , withCredentials = False
--     }
-- {-| `send` replaces `Http.send`. On receipt of a 401 error, it returns a Jwt.Unauthorized.
-- -}
-- send : (Result JwtError a -> msg) -> Request a -> Cmd msg
-- send msgCreator req =
--     let
--         conv : (Result JwtError a -> msg) -> (Result Http.Error a -> msg)
--         conv fn =
--             fn << Result.mapError promote401
--     in
--     Http.send (conv msgCreator) req
--
--
-- {-| `sendCheckExpired` is similar to `send` but, on receiving a 401, it carries out a further check to
-- determine whether the token has expired.
-- -}
-- sendCheckExpired : String -> (Result JwtError a -> msg) -> Request a -> Cmd msg
-- sendCheckExpired token msgCreator req =
--     req
--         |> toTask
--         |> Task.map Result.Ok
--         |> Task.onError (Task.map Err << handleError token)
--         |> Task.perform msgCreator
