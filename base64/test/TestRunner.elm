module Main where

import Console exposing (IO, run)
import ElmTest exposing (consoleRunner)
import Task exposing (Task)
import Tests


console : IO ()
console = consoleRunner Tests.all


port runner : Signal (Task x ())
port runner = run console
