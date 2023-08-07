defmodule Tailscale.Event.Tailnet do
  alias Tailscale.Tailnet

  @type t :: %__MODULE__{
          event: :version_changed | :domain_changed,
          old_value: Tailnet.t(),
          new_value: Tailnet.t()
        }

  defstruct event: nil, old_value: nil, new_value: nil

  def compare(%Tailnet{} = old, %Tailnet{} = new) do
    [version_changed(old, new), domain_changed(old, new)]
  end

  defp make(_event, old_value, new_value) when old_value == new_value, do: nil

  defp make(event, old_value, new_value),
    do: %__MODULE__{event: event, old_value: old_value, new_value: new_value}

  defp version_changed(old, new),
    do: :version_changed |> make(old.tailscale_version, new.tailscale_version)

  defp domain_changed(old, new),
    do: :domain_changed |> make(old.domain, new.domain)
end
