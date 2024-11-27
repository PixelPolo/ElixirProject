import Config

config :loadbalancer,
  port: 8000,
  # Paris by default...
  simulated_coords: %{lat: 48.8566, lon: 2.3522}

config :logger, level: :info
