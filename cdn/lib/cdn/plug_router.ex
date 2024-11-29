defmodule Cdn.PlugRouter do
  @moduledoc """
  A simple HTTP proxy using Plug to forward requests to an origin server with caching
  https://hexdocs.pm/plug/readme.html#plug-router
  """
  use Plug.Router
  alias Cdn.{Health, Registration, Cache, Proxy}
  require Logger

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  # Routing
  get("/", do: Health.health_check(conn))
  get("/register", do: Registration.register_to_loadbalancer(conn))
  get("/cache", do: Cache.get_cache_keys(conn))
  get("/cache/clear", do: Cache.clear_cache(conn))

  # This route will invoke other http request to fetch css and js
  get "/snake" do
    origin_url = Application.fetch_env!(:cdn, :origin_url)
    target_url = "#{origin_url}/snake"
    Proxy.proxy_request(conn, target_url)
  end

  # This general route is for the ones invoked by /snake
  match "/*path" do
    origin_url = Application.fetch_env!(:cdn, :origin_url)
    target_url = "#{origin_url}#{Enum.join(path, "/")}"
    Proxy.proxy_request(conn, target_url)
  end
end
