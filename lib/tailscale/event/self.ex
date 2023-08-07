defmodule Tailscale.Event.Self do
  alias Tailscale.Self

  @type events ::
          :changed | :online | :offline | :active | :inactive | :node_changed | :tags_changed

  @type t :: %__MODULE__{
          event: events(),
          self: Tailscale.Self.t()
        }

  defstruct event: nil, self: nil

  def compare(%Self{} = old, %Self{} = new) do
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

  defp changed(self), do: %__MODULE__{event: :changed, self: self}
  defp online(self), do: %__MODULE__{event: :online, self: self}
  defp offline(self), do: %__MODULE__{event: :offline, self: self}
  defp active(self), do: %__MODULE__{event: :active, self: self}
  defp inactive(self), do: %__MODULE__{event: :inactive, self: self}
  defp node_changed(self), do: %__MODULE__{event: :node_changed, self: self}
  defp tags_changed(self), do: %__MODULE__{event: :tags_changed, self: self}
end
