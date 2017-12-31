# Elm helpers for working with Jwt tokens.

A collection of functions to decode [Jwt tokens](https://jwt.io/), and to use them for authenticated CRUD requests.

## Decode a token

A Jwt is a Base64 string that has three parts

    * header
    * content
    * signature

The library functions `decodeToken` and `tokenDecoder` provide the means to decode the content of a token, while `checkTokenExpiry` and `isExpired` specifically analyse whether the token remains within its expiry time.

## Make an authenticated CRUD request

The library also provides modified versions of Elm standard Http functions to make CRUD requests with the Authorization header set to "bearer <token>"

    let
        url =
            "http://example.com/new"
        body =
            jsonBody <some Value>
    in
        Jwt.post token url body (Json.Decode.field "confirmation" Json.Decode.string)


## Examples

[Examples](https://github.com/simonh1000/elm-jwt/tree/master/examples) are included of the software working with Phoenix and Node backends. More discussion of the Phoenix example can be found in this [blog post](http://simonh1000.github.io/2016/05/phoenix-elm-json-web-tokens/).

## Changelog

* 5.3.0: Adds decoder got Elixir-Guardian token
* 5.2.0: Update NodeJS example
* 5.1.0: Adds a decoder for the Firebase Jwt.
* 5.0.0 (Elm 0.18): Corrects a typo in name of checkTokenExpiry and separates out createRequestObject
* 4.0.0 (Elm 0.18): Elm's Http library has undergone a major rewrite for 0.18 and this library depends upon it. As a result much has changed and you are encouraged to re-look at the examples and the [docs](http://package.elm-lang.org/packages/simonh1000/elm-jwt/latest/Jwt).
* 3.0.0 (Elm 0.18): Elm 0.17 users should use version 2.0.0.
* 2.0.0 (Elm 0.17): The one breaking change is that authenticate now returns `Task JwtError String` rather than `Task never (Result JwtError String)`. It is better to leave it to the user to handle the conversion to a Cmd. Elm 0.16 users should use version 1.0.2.
