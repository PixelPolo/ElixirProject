defmodule Loadbalancer.Health do
  @moduledoc """
  Module `Loadbalancer.Health` for application health checks and client simulation.

  This module performs a health check to verify that the Load Balancer is running.
  Additionally, it simulates a client by providing simulated coordinates.
  """
  import Plug.Conn

  @doc """
  Performs a health check and returns a 200 HTTP response with Load Balancer and client simulation details.

  ## Parameters:
    - `conn`: Plug connection.

  ## Response:
    - HTTP 200 with a message indicating the Load Balancer's status and simulated client details.
  """
  def health_check(conn) do
    # Fetch simulated client coordinates from configuration
    simulated_coords = Application.fetch_env!(:loadbalancer, :simulated_coords)
    port = Application.fetch_env!(:loadbalancer, :port)

    message = """
    Load Balancer is running on port #{port}!
    Simulated client coordinates: Latitude #{simulated_coords.lat}, Longitude #{simulated_coords.lon}.
    """

    send_resp(conn, 200, message)
  end
end
