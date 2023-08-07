# Tailscale

**[WIP]**

This library helps you build an Elixir cluster using Tailscale. You need to have the `tailscale` CLI installed on the machine and authenticated. This library calls the `tailscale status --json` command to get all the information. The status is diffed for changes, which can be subscribed to. The library also implements the `Tailscale.Cluster` module which enables you to connect to any other node on the network simply by having the same tag on Tailscale.

There are plans to support the Tailscale API in the future for reading the status instead of the CLI. The plan is to make it a very powerful library to interact with Tailscale from Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tailscale` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tailscale, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/tailscale>.
