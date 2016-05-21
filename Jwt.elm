module Jwt exposing
    ( JwtError(..)
    , authenticate, decodeToken
    , send, get, post, getWithJwt
    , isExpired, promote401)

{-| Helper functions for Jwt token authentication.

A Jwt Token comprises 3 elements: a header and footer and the content. This package
includes a function to send an authentication request, a function to read the content of a token;
and a function to send GET requests with the token attached.

# API functions
@docs authenticate, decodeToken, send, get, post, getWithJwt, isExpired, promote401

# Errors
@docs JwtError
-}
import Base64
import String
import Time exposing (Time)
import Json.Decode as Json exposing ((:=), Value)
import Http
import Task exposing (Task)

{-| The three errors that can emerge are:
 - network errors (except a 401),
 - a 401 error, which we check is because of token expiry
 - issues with processing (e.g. base 64 decoding) the token, and
 - problems decoding the json data within the content of the token

-}
type JwtError
    = HttpError Http.Error
    | TokenExpired
    | TokenProcessingError String
    | TokenDecodeError String

type alias Token = String

{-| decodeToken converts the token content to an Elm record structure.

    decoderToken dec token

In the event of success, `decodeToken` returns an Elm record structure using the JSON Decoder.

-}
decodeToken : Json.Decoder a -> String -> Result JwtError a
decodeToken dec s =
    let
        f1 = String.split "." <| unurl s
        f2 = List.map fixlength f1
    in
    case f2 of
        (_ :: Result.Err e :: _ :: []) -> Result.Err e
        (_ :: Result.Ok encBody :: _ :: []) ->
            case Base64.decode encBody of
                Result.Ok body ->
                    case Json.decodeString dec body of
                        Result.Ok x -> Result.Ok x
                        Result.Err e -> Result.Err (TokenDecodeError e)
                Result.Err e -> Result.Err (TokenProcessingError e)
        _ -> Result.Err <| TokenProcessingError "Token has invalid shape"

-- Private functions
unurl : String -> String
unurl =
    let fix c =
        case c of
            '-' -> '+'
            '_' -> '/'
            c   -> c
    in String.map fix

fixlength : String -> Result JwtError String
fixlength s =
        case String.length s % 4 of
            0 ->
                Result.Ok s
            2 ->
                Result.Ok <| String.concat [s, "=="]
            3 ->
                Result.Ok <| String.concat [s, "="]
            _ ->
                Result.Err <| TokenProcessingError "Wrong length"

-- TASKS

{-| `authenticate` is a custom Http POST method that sends a stringified
Json object containing the login credentials. It then extracts the token from the
json response from the server and returns it.

    let credentials =
        E.object
            [ ("username", E.string model.uname)
            , ("password", E.string model.pword)
            ]
        |> E.encode 0
    in
    ( model
    , Task.perform
        LoginFail LoginSuccess
        (authenticate tokenStringDecoder "/sessions" credentials)
    )
-}
authenticate : Json.Decoder String -> String -> String -> Task JwtError String
authenticate tokenDecoder url body =
    body
    |> Http.string
    |> post' url
    |> Http.fromJson tokenDecoder
    |> Task.mapError HttpError

-- Private: Same as Http.post but with json headers (instead of default [])
post' : String -> Http.Body -> Task Http.RawError Http.Response
post' url body =
    Http.send Http.defaultSettings
        { verb = "POST"
        , headers = [("Content-type", "application/json")]
        , url = url
        , body = body
        }

{-| send is a replacement for Http.send that includes a Jwt token
-}
send : String -> Token -> Json.Decoder a -> String -> Http.Body -> Task Http.Error a
send verb token dec url body =
    let
        sendtask =
            Http.send Http.defaultSettings
                { verb = verb
                , headers =
                    [ ("Content-type", "application/json")
                    , ("Authorization", "Bearer " ++ token)
                    ]
                , url = url
                , body = body
                }
            |> Http.fromJson dec
    in
    sendtask
    -- sendtask `Task.onError` promoteError token

{-| promote401 promotes a 401 Unauthorized Http reponse to the JwtError TokenExpired.

    Jwt.get token dataDecoder "/api/data"
    `Task.onError` (promote401 token)
    |> Task.perform PostFail PostSucess
-}
promote401 : Token -> Http.Error -> Task JwtError a
promote401 token err =
    case err of
        Http.BadResponse 401 msg ->
            Time.now
                `Task.andThen`
                    \t ->
                        if isExpired t token
                            then Task.fail TokenExpired
                            else Task.fail (HttpError err)
        _ ->
            Task.fail (HttpError err)

{-| get is a replacement for `Http.get` that attaches a provided Jwt token
to the headers of the GET request.

    Task.perform
        PostFail PostSucess
        (get token dataDecoder "/api/data")
-}
get : Token -> Json.Decoder a -> String -> Task Http.Error a
get token dec url =
    send "GET" token dec url Http.empty

{-| post is a replacement for `Http.post` that attaches a provided Jwt token
to the headers, and sets the Content-type to 'application/json'.
-}
post : Token -> Json.Decoder a -> String -> Http.Body -> Task Http.Error a
post token =
    send "POST" token

{-| getWithJwt is an alias for get, provided for backwards compatibility.
-}
getWithJwt : Token -> Json.Decoder a -> String -> Task Http.Error a
getWithJwt =
    get

{-| isExpired checks whether a token remains valid, i.e. it has not expired.

Note: This function assumes that the expiry was set in seconds and thus
multiplies by 100 to compare with javascript time (in milliseconds).
You may need to write a custom version if your Jwt provide works differently.
-}
isExpired : Time -> Token -> Bool
isExpired now token =
    case decodeToken ("exp" := Json.float) token of
        Result.Ok exp ->
            now > (exp * 1000)
        Result.Err _ ->
            True
