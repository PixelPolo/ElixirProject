defmodule Cdn.Health do
  @moduledoc """
  Module `Cdn.Health` for application health checks.
  """
  import Plug.Conn

  @doc """
  Performs a health check and returns a 200 HTTP response with CDN details.

  ## Parameters:
    - `conn`: Plug connection.

  ## Response:
    - HTTP 200 with a message including city and port.
  """
  def health_check(conn) do
    cdn_city = Application.fetch_env!(:cdn, :city)
    port = Application.fetch_env!(:cdn, :port)
    send_resp(conn, 200, "CDN in #{cdn_city} is running on port #{port}!")
  end
end
