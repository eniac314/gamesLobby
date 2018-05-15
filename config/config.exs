# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :games_lobby,
  ecto_repos: [GamesLobby.Repo]

# Configures the endpoint
config :games_lobby, GamesLobbyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HDszwFVoQdljrDAIaM4w4UGnLFy9NhODtMquFw2kdt0a49pM/sCkcGXjjo8qPbw+",
  render_errors: [view: GamesLobbyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: GamesLobby.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
