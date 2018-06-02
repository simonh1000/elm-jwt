module Main exposing (main)

import Browser
import App exposing (Model, Msg, init, update, view)


-- MAIN


main : Program () Model Msg
main =
    Browser.fullscreen
        { init = init
        , update = update
        , view = (\m -> Browser.Page "Jwt test" [ view m ])
        , onNavigation = Nothing
        , subscriptions = \_ -> Sub.none
        }
