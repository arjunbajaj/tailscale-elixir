defmodule Tailscale.ChangeServer do
  use GenServer
  alias Tailscale.Event
  require Logger

  @initial_subscribers_map Event.events_available_for_subscription()

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    refresh_interval = Application.get_env(:tailscale, :refresh_interval, 30_000)
    refresh_interval = Keyword.get(opts, :refresh_interval, refresh_interval)

    state = %{
      refresh_interval: refresh_interval,
      status_map: nil,
      subscribers: @initial_subscribers_map
    }

    {:ok, state, {:continue, :refresh}}
  end

  def handle_continue(:refresh, %{refresh_interval: refresh_interval} = state) do
    Logger.debug("Refreshing Tailscale Status")

    old_status = state.status_map
    new_status = Tailscale.Status.get!()

    if old_status != nil do
      events = Tailscale.Status.diff(old_status, new_status)
      fire_events(events, state)
    end

    state = %{state | status_map: new_status}
    Process.send_after(self(), :refresh, refresh_interval)
    {:noreply, state}
  end

  def handle_info(:refresh, state), do: {:noreply, state, {:continue, :refresh}}

  # ---------------------------
  # --- GENSERVER CALLBACKS ---
  # ---------------------------

  def handle_call(:get_status, _from, state) do
    reply = if state.status_map == nil, do: Tailscale.Local.Status.get!(), else: state.status_map
    {:reply, reply, state}
  end

  def handle_call({:subscribe, target, event}, {pid, _ref}, state) do
    state =
      update_in(state.subscribers[target][event], fn pids -> MapSet.put(pids, pid) end)

    {:reply, :ok, state}
  end

  def handle_call(:subscribe_all, {pid, _ref}, state) do
    state = update_in(state.subscribers.all, fn pids -> MapSet.put(pids, pid) end)
    {:reply, :ok, state}
  end

  # ------------------
  # --- PUBLIC API ---
  # ------------------

  def get_status, do: GenServer.call(__MODULE__, :get_status)

  def subscribe(target), do: subscribe(target, :all)

  @spec subscribe(Event.target(), Event.events()) :: :ok
  def subscribe(target, event) when target in [:self, :peer, :tailnet, :user] do
    GenServer.call(__MODULE__, {:subscribe, target, event})
  end

  def subscribe_all, do: GenServer.call(__MODULE__, :subscribe_all)

  # ---------------------
  # --- PRIVATE FUNCS ---
  # ---------------------

  defp fire_events(:no_change, _), do: nil

  defp fire_events(events, state) do
    events
    |> Enum.map(fn
      %Event.Tailnet{} = event -> {:tailnet, event.event, event}
      %Event.Self{} = event -> {:self, event.event, event}
      %Event.User{} = event -> {:user, event.event, event}
      %Event.Peer{} = event -> {:peer, event.event, event}
    end)
    |> Enum.each(fn
      # peer#changed and self#changed are composite events.
      # they're emitted along with other change events.
      # so here we prevent the :all firehoses from getting these events.
      {:peer, :changed, payload} ->
        trigger(state, :peer, :changed, payload)

      {:self, :changed, payload} ->
        trigger(state, :peer, :changed, payload)

      {target, event, payload} ->
        trigger(state, target, event, payload)
        trigger(state, target, :all, payload)
        trigger_all(state, payload)
    end)
  end

  defp trigger(state, target, event, payload) do
    Enum.each(state.subscribers[target][event], fn pid -> send(pid, {:tailscale, payload}) end)
  end

  defp trigger_all(state, payload) do
    Enum.each(state.subscribers.all, fn pid -> send(pid, {:tailscale, payload}) end)
  end
end
