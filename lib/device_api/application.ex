defmodule DeviceApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DeviceApiWeb.Telemetry,
      DeviceApi.UserRepo,
      DeviceApi.DeviceRepo,
      DeviceApi.DeviceRegistry,
      DeviceDBManager,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:device_api, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:device_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DeviceApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DeviceApi.Finch},
      # Start a worker by calling: DeviceApi.Worker.start_link(arg)
      # {DeviceApi.Worker, arg},
      # Start to serve requests, typically the last entry
      DeviceApiWeb.Endpoint,
      DeviceApi.UserTracker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DeviceApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DeviceApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
