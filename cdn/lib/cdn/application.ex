defmodule Cdn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Cdn.Worker.start_link(arg)
      # {Cdn.Worker, arg}
      {Cachex, name: :cdn_cache},
      {Plug.Cowboy, scheme: :http, plug: Cdn.PlugRouter, options: [port: 9000]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cdn.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
