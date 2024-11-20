defmodule Loadbalancer.PlugRouter do
  @moduledoc """
  A simple HTTP proxy using Plug to forward requests to an origin server.
  It redirects requests for specific routes or dynamically proxies others.
  """

  use Plug.Router

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  # Root route.
  # A health check endpoint to verify that the router is running.
  # Responds with a plain text message.
  get "/" do
    send_resp(conn, 200, "Hello from Loadbalancer.PlugRouter!")
  end

  # Proxy route for `/snake`.
  # Redirects requests from `http://localhost:8001/snake` to the origin server
  # at `http://localhost:4000/snake`.
  # - Returns the origin server's response to the client.
  # - Appends a visible note to the body to indicate that the request was proxied.
  # - If the origin server is unreachable, responds with a `502 Bad Gateway` error.
  get "/snake" do
    target_url = "http://localhost:4000/snake"

    case HTTPoison.get(target_url) do
      # Successful response from the origin server
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
        # Append a note to the response body to indicate proxying
        updated_body = body <> "<div style='text-align: center; margin-top: 20px; color: gray;'>
          <small>Note: This response was proxied through the load balancer.</small>
        </div>"

        # Return the origin's response with the updated body
        conn
        # Copy headers from the origin server
        |> copy_headers(headers)
        |> send_resp(status_code, updated_body)

      # Error response if the origin server is unreachable
      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
    end
  end

  # Catch-all route for proxying other requests.
  # Dynamically forwards all requests to the origin server based on the path.
  # For example:
  #   - `http://localhost:8001/assets/app.css` -> `http://localhost:4000/assets/app.css`
  #   - `http://localhost:8001/js/app.js` -> `http://localhost:4000/js/app.js`
  # Returns the origin server's response as is, without modifying the body.
  match "/*path" do
    target_url = "http://localhost:4000/#{Enum.join(path, "/")}"

    case HTTPoison.get(target_url) do
      # Successful response from the origin server
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
        conn
        # Copy headers from the origin server
        |> copy_headers(headers)
        # Return the origin server's response
        |> send_resp(status_code, body)

      # Error response if the origin server is unreachable
      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 502, "Error fetching resource: #{inspect(reason)}")
    end
  end

  # Copies response headers from the origin server to the Plug connection.
  # This ensures that headers like Content-Type, Cache-Control, and others are preserved.
  #
  # Parameters:
  # - `conn`: The current Plug connection.
  # - `headers`: A list of headers from the origin server's response.
  #
  # Returns:
  # - The updated Plug connection with the headers added.
  defp copy_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, value)
    end)
  end
end
