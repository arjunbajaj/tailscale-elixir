defmodule Tailscale.MixProject do
  use Mix.Project

  def project do
    [
      app: :tailscale,
      version: "0.1.0",
      elixir: "~> 1.15",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # For Package and Docs
      name: "Tailscale",
      description: description(),
      source_url: "https://github.com/arjunbajaj/tailscale-elixir",
      homepage_url: "https://github.com/arjunbajaj/tailscale-elixir",
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},

      # Dev Deps
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Create an Elixir cluster with Tailscale.
    """
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs readme.md license.md changelog.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/arjunbajaj/tailscale-elixir"}
    ]
  end

  defp docs do
    [
      main: "readme",
      api_reference: false,
      # logo: "path/to/logo.png",
      extras: ["readme.md"],
      formatters: ["html"],
      groups_for_modules: [
        Cluster: [
          Tailscale.Supervisor,
          Tailscale.ChangeServer,
          Tailscale.Cluster,
          Tailscale.Lookup
        ],
        CLI: [
          Tailscale.Local.Cmd,
          Tailscale.Local.Status
        ],
        Structs: [
          Tailscale.Status,
          Tailscale.Peer,
          Tailscale.Self,
          Tailscale.Tailnet,
          Tailscale.User
        ],
        Events: [
          Tailscale.Event,
          Tailscale.Event.Peer,
          Tailscale.Event.Self,
          Tailscale.Event.Tailnet,
          Tailscale.Event.User
        ]
      ]
    ]
  end
end
