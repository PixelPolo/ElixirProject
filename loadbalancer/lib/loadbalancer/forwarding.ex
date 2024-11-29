defmodule Loadbalancer.Forwarding do
  @moduledoc """
  Module for forwarding user requests to the nearest CDN.
  """
  import Plug.Conn
  require Logger
  alias Loadbalancer.{CdnRegistry, Utils}

  @doc """
  Forwards a user request to the nearest CDN based on their geographical location.

  ## Parameters:
    - `conn`: Plug connection.
    - `path`: The requested path that needs to be forwarded.

  ## Behavior:
    - Determines the user's geographical location using `Utils.get_geolocation_from_ip/0`.
    - Retrieves the list of registered CDNs from the registry.
    - Finds the nearest CDN using the Haversine distance formula.
    - Redirects the user to the nearest CDN with a 302 response.
    - Responds with 404 if no CDNs are registered.
    - Responds with 500 if the user's location cannot be determined.

  ## Response:
    - **302**: Redirects to the nearest CDN.
    - **404**: No CDN available.
    - **500**: Failed to determine user location.
  """
  def forward_request(conn, path) do
    # Determine the geographical location of the user's IP address
    case Utils.get_geolocation_from_ip() do
      {:ok, user_coords} ->
        # Retrieve the list of CDNs from the registry
        case CdnRegistry.get_cdns() do
          [] ->
            send_resp(conn, 404, "No CDN available for redirection.")

          cdns ->
            # Identify the nearest CDN server based on Haversine distance
            nearest_cdn =
              cdns
              |> Enum.min_by(fn %{lat: cdn_lat, lon: cdn_lon} ->
                Utils.haversine_distance(user_coords.lat, user_coords.lon, cdn_lat, cdn_lon)
              end)

            # Replace host.docker.internal with localhost in the CDN IP
            target_ip = String.replace(nearest_cdn.ip, "host.docker.internal", "localhost")

            # Construct the target URL with the modified IP and the requested path
            target_url = "#{target_ip}/#{Enum.join(path, "/")}"

            # Respond with a 302 redirect to the nearest CDN
            conn
            |> put_resp_header("location", target_url)
            |> send_resp(302, "Redirecting to the nearest CDN in #{nearest_cdn.city}")
        end

      {:error, _reason} ->
        Logger.error("Failed to geolocate user IP")
        send_resp(conn, 500, "Could not determine user location.")
    end
  end
end
