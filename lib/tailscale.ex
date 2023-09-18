defmodule Tailscale do
  defdelegate child_spec(opts \\ []), to: Tailscale.Supervisor
  defdelegate start_link(opts \\ []), to: Tailscale.Supervisor
  defdelegate get_by_tag(tag), to: Tailscale.Lookup, as: :by_tag
  defdelegate get_by_tags(tags, opts \\ []), to: Tailscale.Lookup, as: :by_tags
  defdelegate get_by_hostname(hostname), to: Tailscale.Lookup, as: :by_hostname

  def status, do: Tailscale.Local.Status.get!()
  def topology, do: GenServer.call(Tailscale.Cluster, :cluster_topology)
end
