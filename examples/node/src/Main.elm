module Main exposing (main)

import Browser
import App exposing (Model, Msg, init, update, view)


-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = (\m -> Browser.Document "Jwt test" [ view m ])
        , subscriptions = \_ -> Sub.none
        }
