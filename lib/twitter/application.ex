defmodule Twitter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TwitterWeb.Telemetry,
      # Start the Ecto repository
      Twitter.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Twitter.PubSub},
      # Start Finch
      {Finch, name: Twitter.Finch},
      # Start the Endpoint (http/https)
      TwitterWeb.Endpoint
      # Start a worker by calling: Twitter.Worker.start_link(arg)
      # {Twitter.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Twitter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TwitterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
