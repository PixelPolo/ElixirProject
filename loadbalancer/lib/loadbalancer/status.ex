defmodule Loadbalancer.Status do
  @moduledoc """
  Displays the status of the Load Balancer, including registered CDNs, their cache details,
  and distances to the client, along with the client's location (latitude, longitude, and city).
  """
  import Plug.Conn
  alias Loadbalancer.CdnRegistry
  alias Loadbalancer.Utils

  @doc """
  Returns the list of registered CDNs, their cache status, and their distances to the client.
  """
  def view_status(conn) do
    # Get the list of CDNs
    cdns = CdnRegistry.get_cdns()

    # Get the simulated client location
    {:ok, %{lat: client_lat, lon: client_lon}} = Utils.get_geolocation_from_ip()

    # Get the city from the client's coordinates
    client_city =
      case Utils.get_city_from_coords(client_lat, client_lon) do
        {:ok, city} -> city
        {:error, _reason} -> "Unknown City"
      end

    client_info = """
    Client is located at:
    - Latitude: #{client_lat}
    - Longitude: #{client_lon}
    - City: #{client_city} \n\n\n
    """

    response_body =
      case cdns do
        # No CDN registered
        [] -> client_info <> "No CDN registered in the registry."
        # Send the registry status with cache details and distances
        _ -> client_info <> format_cdn_status(cdns, client_lat, client_lon)
      end

    # Send the formatted response
    send_resp(conn, 200, response_body)
  end

  defp format_cdn_status(cdns, client_lat, client_lon) do
    cdns
    # Loop over each CDN
    |> Enum.map(fn %{ip: ip, city: city, lat: lat, lon: lon} ->
      # Fetch the CDN cache
      cache_keys = fetch_cache_keys(ip)
      # Calculate the distance to the client
      distance = Utils.haversine_distance(client_lat, client_lon, lat, lon)
      # Return the formatted CDN status
      """
      Registered CDN:
      - IP: #{ip}
      - City: #{city}
      - Latitude: #{lat}
      - Longitude: #{lon}
      - Distance to client: #{Float.round(distance, 2)} km
      - Cache Keys:
      #{cache_keys}
      """
    end)
    |> Enum.join("\n\n")
  end

  # Fetch the CDN cache
  defp fetch_cache_keys(cdn_ip) do
    cache_url = "#{cdn_ip}/cache"

    case http_get(cache_url) do
      {:ok, body} -> body
      {:error, reason} -> "Failed to fetch cache: #{inspect(reason)}"
    end
  end

  # Helper for http get
  defp http_get(url) do
    case HTTPoison.get(url, [], recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
