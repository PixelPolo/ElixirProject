defmodule Loadbalancer.PlugRouter do
  @moduledoc """
  A simple Load Balancer router that forwards client requests to the CDN server.
  """
  use Plug.Router

  require Logger

  # Plug pipeline for matching and dispatching routes
  plug(:match)
  plug(:dispatch)

  # Root route for health check
  get "/" do
    send_resp(conn, 200, "Hello from Loadbalancer.PlugRouter!")
  end

  # Catch-all route to forward requests to the CDN server on port 9000
  match "/*path" do
    # Build the target URL by appending the original path to the CDN server URL
    target_url = "http://localhost:9000/#{Enum.join(path, "/")}"

    # Determine the body of the request
    request_body =
      case conn.method do
        "POST" -> Plug.Conn.read_body(conn) |> elem(1)
        "PUT" -> Plug.Conn.read_body(conn) |> elem(1)
        _ -> "" # Use an empty string for GET, DELETE, etc.
      end

    # Forward the client request to the CDN server using HTTPoison
    case HTTPoison.request(
           conn.method |> String.to_atom(), # Convert HTTP method (GET, POST, etc.) to atom
           target_url,                     # Target URL
           request_body,                   # Forward the body (empty string for GET)
           Enum.into(conn.req_headers, []), # Include the original request headers
           recv_timeout: 5000              # Timeout in milliseconds
         ) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
        Logger.info("[LOAD BALANCER] Forwarded request to #{target_url}")
        # Copy response headers from the CDN and send back to the client
        conn
        |> copy_headers(headers)
        |> send_resp(status_code, body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[LOAD BALANCER] Failed to forward request to #{target_url}: #{inspect(reason)}")
        send_resp(conn, 502, "Error forwarding request: #{inspect(reason)}")
    end
  end

  # Helper function to copy response headers to the client
  defp copy_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, value)
    end)
  end
end
