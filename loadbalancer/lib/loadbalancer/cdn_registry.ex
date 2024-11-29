defmodule Loadbalancer.CdnRegistry do
  @moduledoc """
  Manages an in-memory registry of CDN servers using an `Agent`.

  Stores information about CDN servers: IP, city, latitude, and longitude.
  """
  use Agent

  @doc """
  Starts the registry agent with an empty list of CDN servers.
  """
  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Registers a CDN server in the registry.

  ## Parameters
  - `ip`: IP address of the CDN.
  - `city`: City where the CDN is located.
  - `lat`: Latitude of the CDN.
  - `lon`: Longitude of the CDN.
  """
  def register_cdn(ip, city, lat, lon) do
    Agent.update(__MODULE__, fn cdns ->
      [%{ip: ip, city: city, lat: lat, lon: lon} | cdns]
    end)
  end

  @doc """
  Retrieves all registered CDN servers.

  ## Returns
  A list of maps with keys: `:ip`, `:city`, `:lat`, `:lon`.
  """
  def get_cdns do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Removes a CDN from the registry based on its IP.

  ## Parameters:
    - `ip` (String): The IP address of the CDN to remove.
  """
  def remove_cdn(ip) do
    Agent.update(__MODULE__, fn cdns ->
      Enum.reject(cdns, fn cdn -> cdn.ip == ip end)
    end)
  end
end
