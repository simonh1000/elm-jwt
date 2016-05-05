module Tests where

import ElmTest exposing (Test, suite)
import Test.Base64
import Test.BitList


all : Test
all =
  suite "Main" [ Test.Base64.tests
               , Test.BitList.tests
               ]
