defmodule Loadbalancer.PlugRouter do
  @moduledoc """
  A Load Balancer that registers CDN servers and forwards client requests to the nearest one.
  """
  use Plug.Router
  require Logger

  alias Loadbalancer.CdnRegistry

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  #############################################################################
  ##### Health check on endpoint `/` to verify that the router is running #####
  #############################################################################
  get "/" do
    send_resp(conn, 200, "Load Balancer is running!")
  end

  #########################################################
  ##### Route for CDN servers to register dynamically #####
  #########################################################
  post "/cdn/register/:city" do
    # Fetch the city from the url
    city = conn.params["city"]
    # Read the body from the post http method
    {:ok, body, _} = Plug.Conn.read_body(conn)

    # Decode the body
    case Jason.decode(body) do
      {:ok, %{"ip" => ip}} ->
        # Fetch the city coordinates with OpenStreetMap API
        case get_coords_from_city(city) do
          # OpenStreetMap ok
          {:ok, %{lat: lat, lon: lon}} ->
            # Register the CDN inside the CdnRegistry from cdn_registry.ex
            CdnRegistry.register_cdn(ip, city, lat, lon)
            send_resp(conn, 201, "CDN registered successfully!")

          # OpenStreetMap error
          {:error, reason} ->
            Logger.error("Failed to resolve coordinates for #{city}: #{inspect(reason)}")
            send_resp(conn, 400, "Failed to resolve coordinates for city #{city}")
        end

      {:error, _reason} ->
        send_resp(conn, 400, "Invalid payload format. Expected JSON with 'ip'.")
    end
  end

  ##################################################
  ##### Route to view the current CDN registry #####
  ##################################################
  get "/cdn/registry" do
    # Get the CDNs from the registry
    cdns = CdnRegistry.get_cdns()

    case cdns do
      # No CDN registered
      [] ->
        send_resp(conn, 200, "No CDN registered in the registry.")

      # Send the registry status
      _ ->
        response_body =
          cdns
          |> Enum.map(fn %{ip: ip, city: city, lat: lat, lon: lon} ->
            "IP: #{ip}, City: #{city}, Latitude: #{lat}, Longitude: #{lon}"
          end)
          |> Enum.join("\n")

        send_resp(conn, 200, "CDN Registry:\n" <> response_body)
    end
  end

  ###########################################################
  ##### Forward user requests to the nearest CDN server #####
  ###########################################################
  match "/*path" do
    # Determine the geographical location of the user's IP address
    case get_geolocation_from_ip() do
      # Successfully obtained the user's geographical coordinates
      {:ok, user_coords} ->
        case CdnRegistry.get_cdns() do
          # No CDN servers registered in the system
          [] ->
            # Respond with a 404 error indicating no CDNs are available
            send_resp(conn, 404, "No CDN available for redirection.")

          # CDNs are registered, find and redirect to the nearest one
          cdns ->
            # Identify the nearest CDN server based on Haversine distance
            nearest_cdn =
              cdns
              |> Enum.min_by(fn %{lat: cdn_lat, lon: cdn_lon} ->
                haversine_distance(user_coords.lat, user_coords.lon, cdn_lat, cdn_lon)
              end)

            # Construct the target URL for redirection
            target_url = "http://#{nearest_cdn.ip}/#{Enum.join(path, "/")}"

            # Respond with a 302 redirect to the nearest CDN
            conn
            |> put_resp_header("location", target_url)
            |> send_resp(302, "Redirecting to the nearest CDN in #{nearest_cdn.city}")
        end

      # Failed to determine the user's geographical location
      {:error, _reason} ->
        # Log the error for debugging purposes
        Logger.error("Failed to geolocate user IP")

        # Respond with a 500 error indicating the failure to determine the location
        send_resp(conn, 500, "Could not determine user location.")
    end
  end

  ####################################################################
  ##### Helper function to retrieve coordinates from a city name #####
  ####################################################################
  defp get_coords_from_city(city) do
    # Construct the OpenStreetMap API URL with the provided city name
    url =
      "https://nominatim.openstreetmap.org/search?city=#{URI.encode(city)}&format=json&limit=1"

    # Make an HTTP GET request to the OpenStreetMap API
    case HTTPoison.get(url, [], recv_timeout: 5000) do
      # Successfully received a response from the API
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Parse the JSON response body
        case Jason.decode!(body) do
          # Extract the first result containing latitude and longitude
          [result | _] ->
            {:ok, %{lat: String.to_float(result["lat"]), lon: String.to_float(result["lon"])}}

          # No results found for the given city name
          [] ->
            {:error, "City not found"}
        end

      # Failed to make the request or process the response
      {:error, reason} ->
        # Return the error reason
        {:error, reason}
    end
  end

  ##################################################
  ##### Helper to calculate Haversine distance #####
  ##################################################
  defp haversine_distance(lat1, lon1, lat2, lon2) do
    # Earth's radius in kilometers
    radius = 6378

    # Convert the differences in latitude and longitude from degrees to radians
    dlat = (lat2 - lat1) * :math.pi() / 180
    dlon = (lon2 - lon1) * :math.pi() / 180

    # Apply the Haversine formula:
    # a = sin²(Δlat / 2) + cos(lat1) * cos(lat2) * sin²(Δlon / 2)
    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1 * :math.pi() / 180) * :math.cos(lat2 * :math.pi() / 180) *
          :math.pow(:math.sin(dlon / 2), 2)

    # Calculate the central angle (c) using the arctangent
    # c = 2 * atan2(√a, √(1−a))
    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    # Distance is the central angle (c) multiplied by the Earth's radius
    radius * c
  end

  ########################################
  ##### Stub for geolocating user IP #####
  ########################################
  defp get_geolocation_from_ip() do
    %{lat: lat, lon: lon} = Application.get_env(:loadbalancer, :simulated_coords)
    {:ok, %{lat: lat, lon: lon}}
  end
end
