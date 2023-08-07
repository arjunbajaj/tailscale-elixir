defmodule Tailscale do
  defdelegate child_spec(opts \\ []), to: Tailscale.Supervisor
  defdelegate start_link(opts \\ []), to: Tailscale.Supervisor

  def status do
    Tailscale.Local.Status.get!()
  end
end
