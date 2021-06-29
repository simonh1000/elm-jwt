# Elm helpers for working with Jwt tokens.

A collection of functions to decode [Jwt tokens](https://jwt.io/), and to use them for authenticated CRUD requests.

## Decode a token

A Jwt is a Base64 string that has three parts

 - header
 - content
 - signature

The library functions `decodeToken` and `tokenDecoder` provide the means to decode the content of a token, while `checkTokenExpiry` and `isExpired` specifically analyse whether the token remains within its expiry time.

## Make an authenticated CRUD request

The library also provides modified versions of thet standard Http functions to make CRUD requests with the Authorization header set to "bearer <token>"

    let
        url =
            "http://example.com/new"
        body =
            Http.jsonBody <some Value>
    in
        Jwt.Http.post token { url = url, body = body, expect = Http.expectJson OnData (Json.Decode.field "confirmation" Json.Decode.string) }


## Examples

An [example](https://github.com/simonh1000/elm-jwt/tree/master/examples/node) with a Node backend is provided.

I previous blogged about using [elm-jwt with Phoenix](http://simonh1000.github.io/2016/05/phoenix-elm-json-web-tokens/).

## Changelog

* 7.1.1: (0.19.1) Use faster Base64 library (thanks Petre)
* 7.1.0: (0.19) Expose getTokenExpirationMillis (thanks robx)
* 7.0.0: (0.19) Http 2.0.0 necessitated major changes. I took the opportunity to simplify my code and the JwtError type in particular. All token processing functions now also do a cursory check that the header is valid json
* 6.0.0: (0.19) Update
* 5.3.0: Adds decoder got Elixir-Guardian token
* 5.2.0: Update NodeJS example
* 5.1.0: Adds a decoder for the Firebase Jwt.
* 5.0.0 (0.18): Corrects a typo in name of checkTokenExpiry and separates out createRequestObject
* 4.0.0 (0.18): Elm's Http library has undergone a major rewrite for 0.18 and this library depends upon it. As a result much has changed and you are encouraged to re-look at the examples and the [docs](http://package.elm-lang.org/packages/simonh1000/elm-jwt/latest/Jwt).
* 3.0.0 (0.18): Elm 0.17 users should use version 2.0.0.
* 2.0.0 (0.17): The one breaking change is that authenticate now returns `Task JwtError String` rather than `Task never (Result JwtError String)`. It is better to leave it to the user to handle the conversion to a Cmd. Elm 0.16 users should use version 1.0.2.
