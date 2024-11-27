defmodule Loadbalancer.CdnRegistry do
  @moduledoc """
  A simple in-memory registry for storing and managing CDN server information.

  This module uses an `Agent` to maintain a list of registered CDN servers,
  storing their IP address, city, and geographic coordinates (latitude and longitude).
  """

  use Agent

  @doc """
  Starts the `CdnRegistry` agent.

  The agent is initialized with an empty list to store the CDN server information.

  ## Example
      iex> Loadbalancer.CdnRegistry.start_link([])
      {:ok, pid}
  """
  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Registers a new CDN server in the registry.

  Adds the CDN server information (IP, city, latitude, and longitude)
  to the in-memory list.

  ## Parameters
  - `ip` (String): The IP address of the CDN server.
  - `city` (String): The city where the CDN server is located.
  - `lat` (float): The latitude of the CDN server.
  - `lon` (float): The longitude of the CDN server.

  ## Example
      iex> Loadbalancer.CdnRegistry.register_cdn("127.0.0.1", "Paris", 48.8566, 2.3522)
      :ok
  """
  def register_cdn(ip, city, lat, lon) do
    Agent.update(__MODULE__, fn cdns ->
      [%{ip: ip, city: city, lat: lat, lon: lon} | cdns]
    end)
  end

  @doc """
  Retrieves the list of all registered CDN servers.

  ## Returns
  A list of maps, where each map represents a CDN server with the following keys:
  - `:ip` (String): The IP address of the CDN server.
  - `:city` (String): The city where the CDN server is located.
  - `:lat` (float): The latitude of the CDN server.
  - `:lon` (float): The longitude of the CDN server.

  ## Example
      iex> Loadbalancer.CdnRegistry.get_cdns()
      [%{ip: "127.0.0.1", city: "Paris", lat: 48.8566, lon: 2.3522}]
  """
  def get_cdns do
    Agent.get(__MODULE__, & &1)
  end
end
