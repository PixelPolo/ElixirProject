defmodule Cdn.Cache do
  @moduledoc """
  Module `Cdn.Cache` to interact with the CDN cache.
  """
  import Plug.Conn

  @doc """
  Retrieves all keys stored in the CDN cache.

  https://hexdocs.pm/cachex/Cachex.html#keys/2

  ## Parameters:
    - `conn`: Plug connection.

  ## Response:
    - HTTP 200 with the list of cache keys.
    - HTTP 500 if an error occurs.
  """
  def get_cache_keys(conn) do
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

  @doc """
  Clears all entries in the CDN cache.

  https://hexdocs.pm/cachex/Cachex.html#clear/2

  ## Parameters:
    - `conn`: Plug connection.

  ## Response:
    - HTTP 200 on successful cache clearing.
    - HTTP 500 if an error occurs.
  """
  def clear_cache(conn) do
    case Cachex.clear(:cdn_cache) do
      {:ok, _} ->
        send_resp(conn, 200, "Cache cleared successfully.")

      {:error, reason} ->
        send_resp(conn, 500, "Error clearing cache: #{inspect(reason)}")
    end
  end
end
