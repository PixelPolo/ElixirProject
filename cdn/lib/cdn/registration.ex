defmodule Cdn.Registration do
  @moduledoc """
  Module `Cdn.Registration` handles the registration of the CDN server to the Load Balancer.
  """
  import Plug.Conn

  @doc """
  Registers the CDN to the Load Balancer by sending its city and port information.

  ## Parameters:
    - `conn`: Plug connection.

  ## Behavior:
    - Sends a POST request to the Load Balancer with the CDN's city and IP:port.
    - Responds with success (201) or an error based on the Load Balancer's response.
  """
  def register_to_loadbalancer(conn) do
    # Fetch configuration values
    cdn_city = Application.fetch_env!(:cdn, :city)
    port = Application.fetch_env!(:cdn, :port)
    cdn_ip = "http://host.docker.internal:#{port}"

    # Construct the Load Balancer URL
    loadbalancer_url = Application.fetch_env!(:cdn, :loadbalancer_url)
    target_url = "#{loadbalancer_url}/cdn/register/#{cdn_city}"

    # Prepare the payload
    payload = Jason.encode!(%{ip: cdn_ip})

    # Send a POST request to register the CDN
    case HTTPoison.post(target_url, payload, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        send_resp(conn, 201, "Successfully registered to Load Balancer with city #{cdn_city}")

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        send_resp(conn, status_code, "Failed to register: #{body}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 500, "Error connecting to Load Balancer: #{inspect(reason)}")
    end
  end
end
