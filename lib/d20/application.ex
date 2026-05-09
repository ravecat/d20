defmodule D20.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      D20Web.Telemetry,
      D20.Repo,
      {DNSCluster, query: Application.get_env(:d20, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: D20.PubSub},
      {Registry, [name: D20.Registry, keys: :unique]},
      {DynamicSupervisor, [name: D20.Sessions.Supervisor, strategy: :one_for_one]},
      # Start a worker by calling: D20.Worker.start_link(arg)
      # {D20.Worker, arg},
      D20Web.Presence,
      # Start to serve requests, typically the last entry
      D20Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: D20.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    D20Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
