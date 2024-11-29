defmodule Cdn.Proxy do
  @moduledoc """
  Module `Cdn.Proxy`

  Handles proxying requests to origin servers with optional caching and content inspection.
  Adds a note to the response body if the content is HTML.
  """
  import Plug.Conn

  @doc """
  Proxies a request to the given `target_url`, optionally fetching the response from the cache.

  https://hexdocs.pm/httpoison/HTTPoison.html

  ## Parameters:
    - `conn`: Plug connection.
    - `target_url`: The URL to which the request is proxied.

  ## Behavior:
    - Checks if the response for `target_url` is cached; serves from the cache if available.
    - Fetches the response from the origin server if not cached.
    - Adds a note to the body if the content type is HTML.
    - Caches the response for future requests.

  ## Response:
    - HTTP response with the status code and body from the origin server or cache.
  """
  def proxy_request(conn, target_url) do
    # Fetch the city from the application configuration
    cdn_city = Application.fetch_env!(:cdn, :city)

    case Cachex.get(:cdn_cache, target_url) do
      # Response already in cache
      {:ok, cached_body} when not is_nil(cached_body) ->
        send_resp(conn, 200, cached_body)

      # Cache and serve
      _ ->
        case HTTPoison.get(target_url) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
            # Determine if the content is HTML
            content_type =
              List.keyfind(headers, "content-type", 0, {"content-type", ""}) |> elem(1)

            # Add a note
            updated_body =
              if String.contains?(content_type, "text/html") do
                body <>
                  "<div style='text-align: center; margin-top: 20px; color: gray;'>
                  <small>Note: This response was proxied through the CDN in #{cdn_city}</small>
                </div>"
              else
                body
              end

            # Cache the response
            Cachex.put(:cdn_cache, target_url, updated_body)

            # Send the response
            send_resp(conn, status_code, updated_body)

          {:error, %HTTPoison.Error{reason: reason}} ->
            send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
        end
    end
  end
end
