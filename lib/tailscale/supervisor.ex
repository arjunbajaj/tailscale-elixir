defmodule Tailscale.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    tags =  cond do
      opts[:tag] != nil and is_binary(opts[:tag]) -> [opts[:tag]]
      opts[:tags] != nil and is_list(opts[:tags]) -> opts[:tags]
      true -> ["beam"]
    end

    change_server =
      {Tailscale.ChangeServer, [refresh_interval: opts[:refresh_interval] || 30_000]}

    cluster =
      {Tailscale.Cluster,
       [
         tags: tags,
         match_tags: opts[:match_tags],
         disconnect_self_handler: opts[:disconnect_self_handler],
         start_distribution: opts[:start_distribution] || true
       ]}

    children =
      if opts[:start_cluster] == false do
        [change_server]
      else
        [change_server, cluster]
      end

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
