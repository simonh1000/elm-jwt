module Main exposing (main)

import Html.App as Html

-- import Effects exposing (Never)
-- import Task

import App exposing (init, update, view)

main =
  Html.program
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }

-- main =
--   app.html

-- port tasks : Signal (Task.Task Never ())
-- port tasks =
--   app.tasks
