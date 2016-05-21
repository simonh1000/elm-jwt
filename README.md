# Jwt token helper functions.

A collection of Http and Json decoder functions to support with Jwt authentication.

## Version 2.0.0

The one breaking change is that authenticate now returns Task JwtError String rather than Task never (Result JwtError String). It is better to leave it to the user to handle the conversion to a Cmd.

## Examples

[Examples](https://github.com/simonh1000/elm-jwt) are included of the software working with Phoenix and Node backends.

Enjoy,

Simon
