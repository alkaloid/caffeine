# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :caffeine,
  ecto_repos: [Caffeine.Repo]

# Configures the endpoint
config :caffeine, Caffeine.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "56opWNLS2o5g+/VOWXmVtkKIDy/Cbrfbl7hesW0oAn6ysCeCqmAteIXU8Gps/4XD",
  render_errors: [view: Caffeine.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Caffeine.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :slack, api_token: System.get_env("SLACK_TOKEN")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
