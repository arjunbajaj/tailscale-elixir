defmodule Tailscale.Event do
  @type t ::
          Tailscale.Event.Tailnet.t()
          | Tailscale.Event.Self.t()
          | Tailscale.Event.User.t()
          | Tailscale.Event.Peer.t()

  @type targets :: :tailnet | :self | :user | :peer

  @type events ::
          :all
          | :added
          | :removed
          | :changed
          | :online
          | :offline
          | :active
          | :inactive
          | :node_changed
          | :tags_changed
          | :version_changed
          | :domain_changed

  def events_available_for_subscription do
    %{
      all: MapSet.new(),
      tailnet: %{all: MapSet.new(), version_changed: MapSet.new(), domain_changed: MapSet.new()},
      user: %{
        all: MapSet.new(),
        added: MapSet.new(),
        removed: MapSet.new(),
        changed: MapSet.new()
      },
      self: %{
        all: MapSet.new(),
        changed: MapSet.new(),
        online: MapSet.new(),
        offline: MapSet.new(),
        active: MapSet.new(),
        inactive: MapSet.new(),
        node_changed: MapSet.new(),
        tags_changed: MapSet.new()
      },
      peer: %{
        all: MapSet.new(),
        added: MapSet.new(),
        removed: MapSet.new(),
        changed: MapSet.new(),
        online: MapSet.new(),
        offline: MapSet.new(),
        active: MapSet.new(),
        inactive: MapSet.new(),
        node_changed: MapSet.new(),
        tags_changed: MapSet.new()
      }
    }
  end
end
