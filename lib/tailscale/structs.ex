defmodule Tailscale.User do
  @type t :: %__MODULE__{
          id: integer(),
          display_name: binary(),
          username: binary()
        }

  defstruct id: nil, display_name: nil, username: nil
end

defmodule Tailscale.Tailnet do
  @type t :: %__MODULE__{
          name: binary(),
          domain: binary(),
          tailscale_version: binary()
        }

  defstruct name: nil, domain: nil, tailscale_version: nil
end

defmodule Tailscale.Peer do
  @type t :: %__MODULE__{
          id: binary(),
          hostname: binary(),
          ip: binary(),
          node: atom(),
          online?: boolean(),
          active?: boolean(),
          tags: list(binary())
        }

  defstruct id: nil,
            hostname: nil,
            ip: nil,
            node: nil,
            online?: nil,
            active?: nil,
            tags: nil
end

defmodule Tailscale.Self do
  @type t :: Tailscale.Peer.t()
  defstruct Map.to_list(%Tailscale.Peer{})
end
