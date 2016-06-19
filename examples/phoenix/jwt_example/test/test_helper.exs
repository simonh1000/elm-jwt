ExUnit.start

Mix.Task.run "ecto.create", ~w(-r JwtExample.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r JwtExample.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(JwtExample.Repo)

