defmodule Loadbalancer.PlugRouter do
  @moduledoc """
  A Load Balancer that registers CDN servers and forwards client requests to the nearest one.
    https://hexdocs.pm/plug/readme.html#plug-router
  """
  use Plug.Router
  alias Loadbalancer.{Health, Registration, Status, Forwarding}
  require Logger

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  # Routing
  get("/", do: Health.health_check(conn))
  post("/cdn/register/:city", do: Registration.register(conn, city))
  get("/status", do: Status.view_status(conn))
  match("/*path", do: Forwarding.forward_request(conn, path))
end
