# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     JwtExample.Repo.insert!(%JwtExample.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias JwtExample.Repo
alias JwtExample.User
import Comeonin.Bcrypt

[
  %User{
    email: "foo@foo.us",
    password_hash: "secret"
  },
  %User{
    email: "testuser",
    password_hash: hashpwsalt("testpassword")
  }
] |> Enum.each(&Repo.insert!(&1))
