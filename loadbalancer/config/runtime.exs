import Config

config :loadbalancer,
  port: String.to_integer(System.get_env("PORT") || "8000"),
  simulated_coords: %{
    lat: String.to_float(System.get_env("SIMULATED_COORDS_LAT") || "48.8566"),
    lon: String.to_float(System.get_env("SIMULATED_COORDS_LON") || "2.3522")
  }
