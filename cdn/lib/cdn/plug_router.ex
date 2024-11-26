defmodule Cdn.PlugRouter do
  @moduledoc """
  A simple HTTP proxy using Plug to forward requests to an origin server with caching.
  """
  use Plug.Router

  # Logger
  require Logger

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  # Root route.
  # A health check endpoint to verify that the router is running.
  get "/" do
    send_resp(conn, 200, "Hello from Cdn.PlugRouter!")
  end

  # Proxy route for `/snake` with caching
  get "/snake" do
    target_url = "http://localhost:4000/snake"

    case Cachex.get(:cdn_cache, target_url) do
      # Serve from cache if available
      {:ok, cached_body} when not is_nil(cached_body) ->
        Logger.info("Served from cache: #{target_url}")
        send_resp(conn, 200, cached_body)

      # Fetch from origin server if not in cache
      _ ->
        Logger.info("Not in cache: #{target_url}")

        case HTTPoison.get(target_url) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
            updated_body =
              body <> "<div style='text-align: center; margin-top: 20px; color: gray;'>
                <small>Note: This response was proxied through the load balancer.</small>
              </div>"

            # Store the response in the cache
            Cachex.put(:cdn_cache, target_url, updated_body)
            log_cache_content()

            conn
            |> copy_headers(headers)
            |> send_resp(status_code, updated_body)

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to fetch from origin: #{inspect(reason)}")
            send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
        end
    end
  end

  # Catch-all route for proxying other requests with caching
  match "/*path" do
    target_url = "http://localhost:4000/#{Enum.join(path, "/")}"

    case Cachex.get(:cdn_cache, target_url) do
      # Serve from cache if available
      {:ok, cached_body} when not is_nil(cached_body) ->
        Logger.info("Served from cache: #{target_url}")
        send_resp(conn, 200, cached_body)

      # Fetch from origin server if not in cache
      _ ->
        Logger.info("Not in cache: #{target_url}")

        case HTTPoison.get(target_url) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
            Cachex.put(:cdn_cache, target_url, body)
            log_cache_content()

            conn
            |> copy_headers(headers)
            |> send_resp(status_code, body)

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Failed to fetch from origin: #{inspect(reason)}")
            send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
        end
    end
  end

  # Helper function to copy response headers from origin server
  defp copy_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, value)
    end)
  end

  # Helper function to log cache content (keys only)
  defp log_cache_content do
    case Cachex.keys(:cdn_cache) do
      {:ok, keys} ->
        Logger.info("""
        [CACHE CONTENT] Current cache keys:
        #{Enum.map_join(keys, "\n", &("- " <> &1))}
        """)

      {:error, reason} ->
        Logger.error("[ERROR] Failed to inspect cache: #{inspect(reason)}")
    end
  end
end
