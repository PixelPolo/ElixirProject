defmodule Loadbalancer.Heartbeat do
  @moduledoc """
  Periodically checks the health of registered CDNs and updates the registry.

  The `Heartbeat` module runs as a GenServer and performs periodic health checks
  on all CDNs in the registry. If a CDN is unreachable, it is removed from the registry.
  """
  use GenServer
  alias Loadbalancer.CdnRegistry

  # Health check interval in milliseconds
  @interval 1000

  @doc """
  Starts the Heartbeat worker.

  The worker runs in the background and performs periodic health checks.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Initializes the worker and schedules the first health check.

  ## Behavior:
    - Schedules a health check to run after the interval defined by `@interval`.
    - The worker maintains an empty state (`%{}`) as it relies on the registry for CDN data.
  """
  def init(state) do
    schedule_health_check()
    {:ok, state}
  end

  @doc """
  Handles the scheduled health check.

  ## Behavior:
    - Calls `perform_health_check/0` to check the health of all CDNs in the registry.
    - Reschedules the next health check after the interval defined by `@interval`.
  """
  def handle_info(:check_health, state) do
    perform_health_check()
    schedule_health_check()
    {:noreply, state}
  end

  # Schedules the next health check
  defp schedule_health_check do
    # Sends the message `:check_health` to itself after `@interval` milliseconds
    Process.send_after(self(), :check_health, @interval)
  end

  # Checks the health of all registered CDNs
  defp perform_health_check do
    # Fetch the list of CDNs from the registry
    cdns = CdnRegistry.get_cdns()

    cdns
    # Iterate over each CDN
    |> Enum.each(fn %{ip: ip} ->
      # Check if the CDN is healthy
      case check_cdn_health(ip) do
        # If healthy, do nothing
        :ok -> :ok
        # If unhealthy, remove it from the registry
        :error -> CdnRegistry.remove_cdn(ip)
      end
    end)
  end

  # Sends an HTTP GET request to the CDN's health endpoint and checks the response
  defp check_cdn_health(ip) do
    case HTTPoison.get(ip) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        :ok

      _ ->
        :error
    end
  end
end
