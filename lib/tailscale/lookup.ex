defmodule Tailscale.Lookup do
  def by_tag(tag, opts \\ nil) when is_binary(tag), do: by_tags([tag], opts)

  def by_tags(tags, opts \\ [online?: true]) do
    %{peers: peers, self: self} = Tailscale.ChangeServer.get_status()
    nodes = if opts[:include_self] == true, do: peers ++ [self], else: peers

    nodes
    |> then(fn nodes ->
      if opts[:online?] == true do
        nodes |> Enum.filter(fn node -> node.online? == true end)
      else
        nodes
      end
    end)
    |> Enum.filter(fn node ->
      case node.tags do
        nil -> false
        node_tags -> Enum.any?(node_tags, fn tag -> tag in tags end)
      end
    end)
  end

  def by_hostname(hostname) do
    %{peers: peers, self: self} = Tailscale.ChangeServer.get_status()
    nodes = peers ++ [self]

    nodes
    |> Enum.filter(fn node -> node.online? == true end)
    |> Enum.filter(fn node -> node.hostname == hostname end)
    |> List.first()
  end
end
