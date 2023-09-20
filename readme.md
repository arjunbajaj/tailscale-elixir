# A Tailscale Library for Elixir

**This library is a work in progress, but will soon be used in a production cluster.**

This library helps you automatically build an Elixir cluster using Tailscale. The library also helps in interacting with the general state of your Tailnet, so you can lookup nodes by tags and hostnames, and subscribe to various events. The library requires that `tailscale` is connected and running on the host.

## Notes

This library uses the `tailscale status --json` command, which Tailscale has marked experimental. So if Tailscale updates their JSON response, this library may temporarily break. The status is diffed for changes, which is subscribed by the Cluster module to watch for any changes.

> #### Work-In-Progress {: .warning}
>
> I haven't throughly tested the library yet so there could be cluster-killing bugs.
>
> Don't use it for anything critical yet.
>
> I'll improve the library soon and test it.

## Installation

Add the library to your dependencies:

```elixir
def deps do
  [
    {:tailscale, "~> 0.1.0"}
  ]
end
```

[Docs are available here.](https://hexdocs.pm/tailscale)

## Build a Cluster

The simplest way to get started with this library is to add a few nodes to Tailscale with the `beam` tag, drop in this library in your `application.ex`, and everything should just work.

### 1. [On Tailscale] Create a "beam" tag:

In the `Access Controls` tab add the line in the `tagOwners` object:
```json
// Define the tags which can be applied to devices and by which users.
"tagOwners": {
  "tag:beam":     ["autogroup:admin"],
  // ...
},
```

### 2. [On Tailscale] Create an auth-key with the "beam" tag.

* On Tailscale -> Settings -> Keys (in Personal Settings) -> Generate auth key
* You could choose the `Reusable` option to use the same `auth-key` on many VMs.
* Enable the `Tags` option and select the `"tag:beam"` tag from the `Add Tags` option.
* Click Generate Key and copy the key.

### 3. [On VM] Install and authenticate Tailscale on every server

```
tailscale up --auth-key <your-tailscale-auth-key>
```

In a few seconds, you should see the node show up on Tailscale, with the `"beam"` tag on it.

Confirm that Tailscale is working by running:

```
tailscale status
```

### 4. [In Elixir] Just drop in the library in your Application Supervisor

```elixir
defmodule YourApp.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Tailscale,
      ...
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

And that's all. Starting the app will first find all nodes with the `beam` tag and connect to them automatically. As usual, just ensure that the same cookie is set on all nodes. The library will automatically start the Erlang distribution, so don't start it yourself.

To do something different, look through the code and the docs for the modules. I'll document the library further soon.
