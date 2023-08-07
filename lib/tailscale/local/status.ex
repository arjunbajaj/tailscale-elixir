defmodule Tailscale.Local.Status do
  alias Tailscale.Local.Cmd

  def get!, do: parse_status(get_raw_map!())
  def get_raw!, do: Cmd.exec(~w[status --json], json: false)
  def get_raw_map!, do: Cmd.exec(~w[status --json], json: true)

  defp parse_status(status_json) do
    tailnet = %Tailscale.Tailnet{
      domain: status_json["MagicDNSSuffix"],
      name: status_json["CurrentTailnet"]["Name"],
      tailscale_version: status_json["Version"]
    }

    self = parse_peer(status_json["Self"], true)
    peers = Enum.map(status_json["Peer"], fn {_k, v} -> parse_peer(v) end)
    users = parse_users(status_json["User"])

    %Tailscale.Status{tailnet: tailnet, users: users, self: self, peers: peers}
  end

  defp parse_users(users_map) do
    users_map
    |> Enum.filter(fn {_k, v} -> v["LoginName"] != "tagged-devices" end)
    |> Enum.map(fn {_k, v} ->
      %Tailscale.User{id: v["ID"], username: v["LoginName"], display_name: v["DisplayName"]}
    end)
  end

  defp parse_peer(peer_map, is_self \\ false) do
    id = peer_map["ID"]
    hostname = peer_map["HostName"]
    online? = peer_map["Online"]
    active? = peer_map["Active"]
    tags = peer_map["Tags"]
    [ipv4, _ipv6] = peer_map["TailscaleIPs"]
    _domain = peer_map["DNSName"]
    _os = peer_map["OS"]
    _is_exit_node? = peer_map["ExitNode"]
    _relay = peer_map["Relay"]

    peer = [
      id: id,
      hostname: hostname,
      ip: ipv4,
      node: :"#{hostname}@#{ipv4}",
      online?: online?,
      active?: active?,
      tags: parse_tags(tags)
    ]

    case is_self do
      true -> struct!(Tailscale.Self, peer)
      false -> struct!(Tailscale.Peer, peer)
    end
  end

  defp parse_tags(nil), do: nil

  defp parse_tags(tags) do
    Enum.map(tags, fn "tag:" <> tag -> tag end)
    |> Enum.sort()
  end
end
