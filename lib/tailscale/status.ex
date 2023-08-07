defmodule Tailscale.Status do
  alias Tailscale.{Tailnet, User, Self, Peer, Event}

  @type t :: %__MODULE__{
          tailnet: Tailnet.t(),
          users: list(User.t()),
          self: Self.t(),
          peers: list(Peer.t())
        }

  defstruct tailnet: nil, users: nil, self: nil, peers: nil

  def get! do
    Tailscale.Local.Status.get!()
  end

  def diff(%__MODULE__{} = old, %__MODULE__{} = new) do
    [
      Event.Tailnet.compare(old.tailnet, new.tailnet),
      Event.Self.compare(old.self, new.self),
      Event.User.compare_lists(old.users, new.users),
      Event.Peer.compare_lists(old.peers, new.peers)
    ]
    |> List.flatten()
    |> Enum.filter(&(&1 != nil))
    |> then(fn
      [] -> :no_change
      events -> events
    end)
  end
end
