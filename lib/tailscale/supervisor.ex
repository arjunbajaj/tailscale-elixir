defmodule Tailscale.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    change_server =
      {Tailscale.ChangeServer, [refresh_interval: opts[:refresh_interval] || 30_000]}

    cluster =
      {Tailscale.Cluster,
       [
         tags: opts[:tags],
         match_tags: opts[:match_tags] || :all,
         disconnect_self_handler: opts[:disconnect_self_handler],
         start_distribution: opts[:start_distribution] || true
       ]}

    children =
      if opts[:start_cluster] == true do
        [change_server, cluster]
      else
        [change_server]
      end

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
