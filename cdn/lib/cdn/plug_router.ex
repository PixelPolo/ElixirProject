defmodule Cdn.PlugRouter do
  @moduledoc """
  A simple HTTP proxy using Plug to forward requests to an origin server with caching
  https://hexdocs.pm/plug/readme.html#plug-router
  """
  use Plug.Router
  require Logger

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  #############################################################################
  ##### Health check on endpoint `/` to verify that the router is running #####
  #############################################################################
  get "/" do
    send_resp(conn, 200, "CDN is running!")
  end

  ##########################################################
  ##### Route `/register` to register to Load Balancer #####
  ##########################################################
  get "/register" do
    # Fetch the city and the port from the application configuration or environment
    cdn_city = Application.fetch_env!(:cdn, :city)
    port = Application.fetch_env!(:cdn, :port)

    # Construct the Load Balancer URL with the city included in the endpoint
    load_balancer_url = "http://localhost:8000/cdn/register/#{cdn_city}"

    # Build the CDN's IP address and port (assuming it's running locally) and create a paylod
    cdn_ip = "localhost:#{port}"
    payload = Jason.encode!(%{ip: cdn_ip})

    # Send a POST request to the Load Balancer's register endpoint with the payload
    case HTTPoison.post(load_balancer_url, payload, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        send_resp(conn, 201, "Successfully registered to Load Balancer with city #{cdn_city}")

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        send_resp(conn, status_code, "Failed to register: #{body}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 500, "Error connecting to Load Balancer: #{inspect(reason)}")
    end
  end

  #################################################
  ##### Proxy route for `/snake` with caching #####
  #################################################
  get "/snake" do
    # Origin server url
    target_url = "http://localhost:4000/snake"

    # Fetch the city from the application configuration
    cdn_city = Application.fetch_env!(:cdn, :city)

    # Try to get resources from cache
    case Cachex.get(:cdn_cache, target_url) do
      # Serve from cache if available
      {:ok, cached_body} when not is_nil(cached_body) ->
        send_resp(conn, 200, cached_body)

      # Fetch from origin server if not in cache
      _ ->
        case HTTPoison.get(target_url) do
          # Successful fetch
          {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: _headers}} ->
            updated_body =
              body <> "<div style='text-align: center; margin-top: 20px; color: gray;'>
              <small>Note: This response was proxied through the CDN in #{cdn_city}</small>
            </div>"

            # Store the response in the cache
            Cachex.put(:cdn_cache, target_url, updated_body)

            # Send the response directly to the client
            send_resp(conn, status_code, updated_body)

          # Error fetch
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to fetch from origin: #{inspect(reason)}")
            send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
        end
    end
  end

  #################################################
  ##### Route `/cache` to see the cache state #####
  #################################################
  get "/cache" do
    case Cachex.keys(:cdn_cache) do
      {:ok, keys} ->
        response_body = """
        Cache Keys:
        #{inspect(keys, pretty: true)}
        """

        send_resp(conn, 200, response_body)

      {:error, reason} ->
        send_resp(conn, 500, "Error retrieving cache keys: #{inspect(reason)}")
    end
  end

  ###################################################
  ##### Route `/cache/clear` to clear the cache #####
  ###################################################
  get "/cache/clear" do
    case Cachex.clear(:cdn_cache) do
      {:ok, _} ->
        send_resp(conn, 200, "Cache cleared successfully.")

      {:error, reason} ->
        send_resp(conn, 500, "Error clearing cache: #{inspect(reason)}")
    end
  end

  ####################################################################
  ##### Catch-all route for proxying other requests with caching #####
  ####################################################################
  match "/*path" do
    # Origin server url
    target_url = "http://localhost:4000/#{Enum.join(path, "/")}"

    # Try to get resources from cache

    case Cachex.get(:cdn_cache, target_url) do
      # Serve from cache if available
      {:ok, cached_body} when not is_nil(cached_body) ->
        send_resp(conn, 200, cached_body)

      # Fetch from origin server if not in cache
      _ ->
        # Fetch resources with HTTPoison
        case HTTPoison.get(target_url) do
          # Successful fetch
          {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: _headers}} ->
            # Store the response in the cache
            Cachex.put(:cdn_cache, target_url, body)

            # Send the response
            conn
            |> send_resp(status_code, body)

          # Error fetch
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to fetch from origin: #{inspect(reason)}")
            send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
        end
    end
  end
end
