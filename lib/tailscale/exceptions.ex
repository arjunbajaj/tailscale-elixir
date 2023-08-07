defmodule Tailscale.Exceptions do
  defmodule TailscaleNotRunning do
    @msg "Tailscale is not running on the host."
    defexception message: @msg
  end

  defmodule TailscaleNotFound do
    @msg "Cannot find Tailscale binary. Ensure Tailscale is installed on your operating system."
    defexception message: @msg
  end

  defmodule TailscaleCLIError do
    defexception message: "Unhandled Tailscale CLI Error", code: 1
  end
end
