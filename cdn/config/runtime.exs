import Config

config :cdn,
  port: String.to_integer(System.get_env("PORT") || "9000"),
  city: System.get_env("CITY") || "Fribourg"
