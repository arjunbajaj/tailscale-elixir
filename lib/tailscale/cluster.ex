defmodule Tailscale.Cluster do
  use GenServer
  alias Tailscale.ChangeServer
  alias Tailscale.Event
  require Logger

  @ensure_interval 30_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    tags = opts[:tags]
    match = opts[:match_tags] || :all

    if opts[:start_distribution] != false do
      start_distribution(Tailscale.ChangeServer.get_status().self)
    end

    cond do
      match not in [:all, :any] ->
        raise ArgumentError, "Option `match_tags` needs to be either `:all` or `:any`."

      tags == nil ->
        raise ArgumentError, "Option `tags` is required."

      not is_list(tags) ->
        raise ArgumentError,
              "Option `tags` needs to be a list of strings (without the Tailscale \"tag:\" qualifier)."

      true ->
        nil
    end

    tags =
      Enum.map(tags, fn
        "tag:" <> tag -> tag
        tag -> tag
      end)
      |> Enum.uniq()

    state = %{
      tags: tags,
      match: match,
      cluster_topology: %{},
      disconnect_self_handler: opts[:disconnect_self_handler]
    }

    {:ok, state, {:continue, :start}}
  end

  def handle_continue(:start, state) do
    # Subscribe to peer changes
    ChangeServer.subscribe(:peer, :added)
    ChangeServer.subscribe(:peer, :removed)
    ChangeServer.subscribe(:peer, :online)
    ChangeServer.subscribe(:peer, :offline)
    ChangeServer.subscribe(:peer, :tags_changed)

    # Subscribe to self changes
    ChangeServer.subscribe(:self, :offline)
    ChangeServer.subscribe(:self, :tags_changed)
    ChangeServer.subscribe(:self, :node_changed)

    # Connect to all nodes that are currently online
    state = ensure_connected(state)

    # Ensure connected repeatedly
    Process.send_after(self(), :ensure_connected, @ensure_interval)

    {:noreply, state}
  end

  # ---------------------------
  # --- EVENT SUBSCRIPTIONS ---
  # ---------------------------

  def handle_info({:tailscale, %Event.Self{event: :offline}}, state) do
    disconnect_self(:offline, "Tailscale is offline", state)
  end

  def handle_info({:tailscale, %Event.Self{event: :tags_changed, self: self}}, state) do
    case check_if_peer_matches_tags(self, state) do
      true -> nil
      false -> disconnect_self(:tags_changed, "Machine tags changed on Tailscale", state)
    end
  end

  def handle_info({:tailscale, %Event.Self{event: :node_changed}}, state) do
    disconnect_self(:hostname_changed, "Machine hostname changed on Tailscale", state)
  end

  def handle_info({:tailscale, %Event.Peer{event: :added, peer: peer}}, state) do
    connect_to_node(peer, state)
  end

  def handle_info({:tailscale, %Event.Peer{event: :online, peer: peer}}, state) do
    connect_to_node(peer, state)
  end

  def handle_info({:tailscale, %Event.Peer{event: :removed, peer: peer}}, state) do
    disconnect_from_node(peer, state)
  end

  def handle_info({:tailscale, %Event.Peer{event: :offline, peer: peer}}, state) do
    disconnect_from_node(peer, state)
  end

  def handle_info({:tailscale, %Event.Peer{event: :tags_changed, peer: peer}}, state) do
    case check_if_peer_matches_tags(peer, state) do
      true -> connect_to_node(peer, state)
      false -> disconnect_from_node(peer, state)
    end
  end

  def handle_info(:ensure_connected, state) do
    Process.send_after(self(), :ensure_connected, @ensure_interval)
    {:noreply, ensure_connected(state)}
  end

  def terminate(reason, _state) do
    Logger.debug("Tailscale.Cluster is terminating: #{inspect(reason)}.")
    Node.stop()
  end

  # ---------------------
  # --- PRIVATE FUNCS ---
  # ---------------------

  defp start_distribution(%Tailscale.Self{} = self) do
    case Node.stop() do
      {:error, :not_allowed} ->
        raise """
        Elixir was configured to start the distribution.
        It cannot be stopped.
        Do not pass --sname or --name to avoid starting the distribution.
        Tailscale.Cluster will automatically setup the distribution for you.
        """

      _ ->
        case Node.start(self.node, :longnames) do
          {:ok, _pid} ->
            :ok

          {:error, _} ->
            raise "Failed to start Erlang distribution."
        end
    end
  end

  defp ensure_connected(state) do
    Tailscale.ChangeServer.get_status()
    |> Map.get(:peers)
    |> Enum.filter(&check_if_peer_matches_tags(&1, state))
    |> Enum.filter(fn peer -> peer.online == true end)
    |> Enum.map(fn peer ->
      case Node.connect(peer.node) do
        true -> {peer.id, peer}
        false -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.into(%{})
    |> then(fn cluster_topology ->
      %{state | cluster_topology: cluster_topology}
    end)
  end

  defp disconnect_self(reason, msg, state) do
    if state.disconnect_self_handler != nil do
      state.disconnect_self_handler.(reason)
    else
      Logger.debug("Restarting Application: #{msg}")
      System.stop(1)
    end

    {:noreply, state}
  end

  defp connect_to_node(%Tailscale.Peer{} = peer, state) do
    state =
      case Node.connect(peer.node) do
        true ->
          update_in(state.cluster_topology, fn topology -> Map.put(topology, peer.id, peer) end)

        false ->
          state
      end

    {:noreply, state}
  end

  defp disconnect_from_node(%Tailscale.Peer{} = peer, state) do
    state =
      case Node.disconnect(peer.node) do
        true ->
          update_in(state.cluster_topology, fn topology -> Map.delete(topology, peer.id) end)

        false ->
          state
      end

    {:noreply, state}
  end

  defp check_if_peer_matches_tags(%{tags: nil} = _peer, _state), do: false

  defp check_if_peer_matches_tags(peer, state) do
    case state.match do
      :all -> peer.tags |> Enum.all?(fn tag -> tag in state.tags end)
      :any -> peer.tags |> Enum.any?(fn tag -> tag in state.tags end)
    end
  end
end
