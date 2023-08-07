defmodule Tailscale.Event.Peer do
  alias Tailscale.Peer

  @type events ::
          :added
          | :removed
          | :changed
          | :online
          | :offline
          | :active
          | :inactive
          | :node_changed
          | :tags_changed

  @type t :: %__MODULE__{
          event: events(),
          peer: Tailscale.Peer.t()
        }

  defstruct event: nil, peer: nil

  @spec compare_lists([Peer.t()], [Peer.t()]) :: [__MODULE__.t()]
  def compare_lists(old_peers, new_peers) do
    old_set = MapSet.new(old_peers, fn peer -> peer.id end)
    new_set = MapSet.new(new_peers, fn peer -> peer.id end)

    added_ids = MapSet.difference(new_set, old_set)
    removed_ids = MapSet.difference(old_set, new_set)
    unchanged_ids = MapSet.intersection(old_set, new_set) |> MapSet.to_list()

    added_events =
      new_peers
      |> Enum.filter(fn p -> p.id in added_ids end)
      |> Enum.map(fn p -> %__MODULE__{event: :added, peer: p} end)

    removed_events =
      old_peers
      |> Enum.filter(fn p -> p.id in removed_ids end)
      |> Enum.map(fn p -> %__MODULE__{event: :removed, peer: p} end)

    changed_events =
      unchanged_ids
      |> Enum.map(fn id ->
        old_peer = Enum.find(old_peers, fn peer -> peer.id == id end)
        new_peer = Enum.find(new_peers, fn peer -> peer.id == id end)

        case Map.equal?(old_peer, new_peer) do
          true -> nil
          false -> compare(old_peer, new_peer)
        end
      end)
      |> List.flatten()
      |> Enum.filter(&(&1 != nil))

    events = added_events ++ removed_events ++ changed_events

    events
  end

  def compare(%Peer{} = old, %Peer{} = new) do
    [
      if(old.online? != new.online? and new.online? == true, do: online(new)),
      if(old.online? != new.online? and new.online? == false, do: offline(new)),
      if(old.active? != new.active? and new.active? == true, do: active(new)),
      if(old.active? != new.active? and new.active? == false, do: inactive(new)),
      if(old.node != new.node, do: node_changed(new)),
      if(old.tags != new.tags, do: tags_changed(new))
    ]
    |> Enum.filter(&(&1 != nil))
    |> then(fn
      [] -> []
      events -> events ++ [changed(new)]
    end)
  end

  def changed(peer), do: %__MODULE__{event: :changed, peer: peer}
  def online(peer), do: %__MODULE__{event: :online, peer: peer}
  def offline(peer), do: %__MODULE__{event: :offline, peer: peer}
  def active(peer), do: %__MODULE__{event: :active, peer: peer}
  def inactive(peer), do: %__MODULE__{event: :inactive, peer: peer}
  def node_changed(peer), do: %__MODULE__{event: :node_changed, peer: peer}
  def tags_changed(peer), do: %__MODULE__{event: :tags_changed, peer: peer}
end
