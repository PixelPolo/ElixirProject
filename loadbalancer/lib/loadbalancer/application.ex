defmodule Loadbalancer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Fetch runtime environment variables or defaults
    port = Application.get_env(:loadbalancer, :port, 8000)

    simulated_coords =
      Application.get_env(:loadbalancer, :simulated_coords, %{lat: 0.0, lon: 0.0})

    lat = simulated_coords[:lat]
    lon = simulated_coords[:lon]

    # Log the Load Balancer status
    Logger.info(
      "Starting Load Balancer on port #{port} with simulated coordinates LAT=#{lat}, LON=#{lon}"
    )

    children = [
      # Starts the CDN Registry
      Loadbalancer.CdnRegistry,

      # Heartbeat to check the CDNs life status
      {Loadbalancer.Heartbeat, []},

      # Plug process for the http router
      {Plug.Cowboy, scheme: :http, plug: Loadbalancer.PlugRouter, options: [port: port]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loadbalancer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
