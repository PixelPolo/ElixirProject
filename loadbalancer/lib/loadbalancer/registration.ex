defmodule Loadbalancer.Registration do
  @moduledoc """
  Module for registering CDNs with the Load Balancer.
  """
  import Plug.Conn
  require Logger
  alias Loadbalancer.CdnRegistry
  alias Loadbalancer.Utils

  @doc """
  Registers a CDN server with the Load Balancer if it does not already exist.

  ## Parameters:
    - `conn`: Plug connection.
    - `city`: The city name provided in the route.

  ## Behavior:
    - Reads the body of the POST request and decodes it as JSON.
    - Checks if the CDN IP is already in the registry.
    - If not registered, fetches the geographical coordinates and registers the CDN.
    - Responds with appropriate status codes based on the result of the operation.

  ## Response:
    - **201**: Registration successful.
    - **409**: CDN already exists in the registry.
    - **400**: Invalid payload or failed to resolve city coordinates.
  """
  def register(conn, city) do
    # Read the body from the POST request
    {:ok, body, _} = Plug.Conn.read_body(conn)

    # Decode the JSON body
    case Jason.decode(body) do
      # If JSON is valid and contains "ip"
      {:ok, %{"ip" => ip}} ->
        # Check if the CDN is already registered
        if cdn_exists?(ip) do
          send_resp(conn, 409, "CDN is already registered.")
        else
          # Fetch the geographical coordinates of the city
          case Utils.get_coords_from_city(city) do
            # Successfully fetched coordinates
            {:ok, %{lat: lat, lon: lon}} ->
              # Register the CDN in the registry
              CdnRegistry.register_cdn(ip, city, lat, lon)
              send_resp(conn, 201, "CDN registered successfully!")

            # Failed to resolve city coordinates
            {:error, reason} ->
              Logger.error("Failed to resolve coordinates for #{city}: #{inspect(reason)}")
              send_resp(conn, 400, "Failed to resolve coordinates for city #{city}")
          end
        end

      # Invalid JSON format or missing "ip"
      {:error, _reason} ->
        send_resp(conn, 400, "Invalid payload format. Expected JSON with 'ip'.")
    end
  end

  defp cdn_exists?(ip) do
    # Check if the CDN with the given IP exists in the registry
    CdnRegistry.get_cdns()
    |> Enum.any?(fn %{ip: existing_ip} -> existing_ip == ip end)
  end
end
