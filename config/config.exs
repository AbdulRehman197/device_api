# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :device_api,
  ecto_repos: [DeviceApi.UserRepo, DeviceApi.DeviceRepo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :device_api, DeviceApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DeviceApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DeviceApi.PubSub,
  live_view: [signing_salt: "k3sK/woJ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :device_api, DeviceApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :device_api, :pow,
  user: DeviceApi.Users.User,
  repo: DeviceApi.UserRepo,
  user_id_field: :username

config :device_api, :app_password,
  app_password: "9#7Jk@!!296Emgs2ho0l4e454@"


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
