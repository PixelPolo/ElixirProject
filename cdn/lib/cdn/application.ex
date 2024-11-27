defmodule Cdn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Fetch config.exs
    port = Application.get_env(:cdn, :port, 9000)
    city = Application.get_env(:cdn, :city, "Unknown City")

    # Log the CDN status
    Logger.info("Starting CDN for city #{city} on port #{port}")

    children = [
      # Cachex process to manage cache
      {Cachex, name: :cdn_cache},

      # Plug process for the http router
      {Plug.Cowboy, scheme: :http, plug: Cdn.PlugRouter, options: [port: port]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cdn.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
