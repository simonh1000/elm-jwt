# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :jwt_example, JwtExample.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbopGo9lz5GcuLi5+Bi5Hxm0W2It2HlatYAUft8qs4UfUFlHV7Wkg9SdoAaXHDVZ",
  render_errors: [view: JwtExample.ErrorView, accepts: ~w(html json)],
  pubsub: [name: JwtExample.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :jwt_example,
   ecto_repos: [JwtExample.Repo]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
