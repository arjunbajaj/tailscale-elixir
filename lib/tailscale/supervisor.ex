defmodule Tailscale.Supervisor do
  @moduledoc """
  Starting the Supervisor starts the ChangeServer and the Cluster servers.

  To prevent starting the Cluster, pass `[start_cluster: false]`.

  By default, the ChangeServer re-runs the `tailscale status --json` command every 30 seconds,
  and then diffs the output. To change the refresh interval,
  pass `[refresh_interval: integer_in_milliseconds]`.
  """
  use Supervisor

  @doc """
  Starts the Tailscale Supervisor.

  Tailscale.Supervisor starts the Tailscale.ChangeServer and Tailscale.Cluster GenServers.

  You can pass options to control the `refresh_interval` of the ChangeServer, and the options for the Cluster in the opts of the Supervisor.

  ## Options

  * `:refresh_interval` - The interval in milliseconds to refresh the Tailscale status. Defaults to `30_000` (30 seconds).

  * `:tag | :tags` - Either a tag string or a list of tags (without the "tag:" prefix that Tailscale adds). Defaults to `["beam"]`.

  * `:match_tags` - Can be `:any | :all`. Defaults to `:any`.

  * `:start_cluster` - Whether to start the Tailscale Cluster. Defaults to `true`.

  * `:start_distribution` - Whether to start the Tailscale Distribution. Defaults to `true`. If you pass `false` here, you would have to start the distribution yourself but ensure that the format is `<tailscale_node_name>@<tailscale_node_ip>`. For now, this library does not support automatically connecting to nodes named differently.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    tags =
      cond do
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
