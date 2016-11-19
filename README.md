# Elm helpers for working with Jwt tokens.

A collection of Elm Http and Json decoder functions to support Jwt authentication.

## Version 4.0.0 (Elm 0.18)

Elm's Http library has undergone a major rewrite for 0.18 and this library depends upon it. As a result much has changed and you are encouraged to re-look at the examples and the docs.

## Version 3.0.0 (Elm 0.18)

Initial version

Elm 0.17 users should use version 2.0.0.

## Version 2.0.0 (Elm 0.17)

The one breaking change is that authenticate now returns `Task JwtError String` rather than `Task never (Result JwtError String)`. It is better to leave it to the user to handle the conversion to a Cmd.

Elm 0.16 users should use version 1.0.2.

## Examples

[Examples](https://github.com/simonh1000/elm-jwt/tree/master/examples) are included of the software working with Phoenix and Node backends. More discussion of the Phoenix example can be found in this [blog post](http://simonh1000.github.io/2016/05/phoenix-elm-json-web-tokens/).
