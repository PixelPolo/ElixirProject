defmodule Loadbalancer.Utils do
  @moduledoc """
  Utility module for geographical calculations and API operations.

  Provides functions to:
  - Get coordinates from a city name using the Nominatim API.
  - Get a city name from coordinates using the Nominatim API.
  - Calculate distances between geographical points (Haversine formula).
  - Simulate geolocation data based on configuration.
  """

  @doc """
  Fetches the coordinates (latitude and longitude) of a city using the Nominatim API.

  ## Parameters:
    - `city` (String): The name of the city.

  ## Returns:
    - `{:ok, %{lat: float, lon: float}}` on success.
    - `{:error, reason}` if the city cannot be resolved.
  """
  def get_coords_from_city(city) do
    url =
      "https://nominatim.openstreetmap.org/search?city=#{URI.encode(city)}&format=json&limit=1"

    case HTTPoison.get(url, [], recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          [result | _] ->
            {:ok, %{lat: String.to_float(result["lat"]), lon: String.to_float(result["lon"])}}

          [] ->
            {:error, "City not found"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves the city name from geographical coordinates using the Nominatim API.

  ## Parameters:
    - `lat` (float): Latitude of the location.
    - `lon` (float): Longitude of the location.

  ## Returns:
    - `{:ok, city}` on success.
    - `{:error, reason}` if the city cannot be determined.
  """
  def get_city_from_coords(lat, lon) do
    url =
      "https://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&format=json"

    case HTTPoison.get(url, [], recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"address" => %{"city" => city}} -> {:ok, city}
          %{"address" => %{"town" => town}} -> {:ok, town}
          _ -> {:error, "City not found in response"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates the Haversine distance between two geographical points.

  ## Parameters:
    - `lat1`, `lon1` (float): Coordinates of the first point.
    - `lat2`, `lon2` (float): Coordinates of the second point.

  ## Returns:
    - Distance in kilometers as a float.
  """
  def haversine_distance(lat1, lon1, lat2, lon2) do
    radius = 6378
    dlat = (lat2 - lat1) * :math.pi() / 180
    dlon = (lon2 - lon1) * :math.pi() / 180

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1 * :math.pi() / 180) * :math.cos(lat2 * :math.pi() / 180) *
          :math.pow(:math.sin(dlon / 2), 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    radius * c
  end

  @doc """
  Simulates a user's geographical location using configured values.

  ## Returns:
    - `{:ok, %{lat: float, lon: float}}`.
  """
  def get_geolocation_from_ip() do
    %{lat: lat, lon: lon} = Application.get_env(:loadbalancer, :simulated_coords)
    {:ok, %{lat: lat, lon: lon}}
  end
end
