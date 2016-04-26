module Main (main) where

import StartApp

import Effects exposing (Never)
import Task

import App exposing (init, update, view)

app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }

main =
  app.html

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks
