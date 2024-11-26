defmodule Loadbalancer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Loadbalancer.Worker.start_link(arg)
      # {Loadbalancer.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Loadbalancer.PlugRouter, options: [port: 8000]},
      {Plug.Cowboy, scheme: :http, plug: Loadbalancer.PlugServer, options: [port: 8001]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loadbalancer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
