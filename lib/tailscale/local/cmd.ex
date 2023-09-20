defmodule Tailscale.Local.Cmd do
  @moduledoc """
  Execute a command on the local Tailscale CLI.

  The Tailscale CLI should be running and active.

  On macOS, the Tailscale CLI is located inside the Tailscale.app bundle.
  On Linux, the Tailscale CLI is located by finding it in the $PATH.
  """

  alias Tailscale.Exceptions.{TailscaleCLIError, TailscaleNotFound, TailscaleNotRunning}

  @doc """
  Execute a Tailscale CLI command.

  This function will raise an exception if the Tailscale CLI command fails.
  It also can optionally decode the output as JSON (helpful for commands that return JSON output).
  However, if it fails to decode JSON, it will raise.
  """
  def exec(args, opts \\ [])

  def exec(args, opts) when is_binary(args) do
    exec(String.split(args, " "), opts)
  end

  def exec(args, opts) when is_list(args) do
    decode_json? = if opts[:json] == true, do: true, else: false

    case System.cmd(find_tailscale_executable(), args, stderr_to_stdout: true) do
      {output, 0} ->
        if(decode_json?, do: Jason.decode!(output), else: output)

      {output, code} ->
        if String.contains?(output, "is Tailscale running?") do
          raise TailscaleNotRunning
        else
          raise TailscaleCLIError, message: output, code: code
        end
    end
  end

  # The executable on Mac is inside the Tailscale.app directory.
  # On Linux, searching the $PATH works.
  defp find_tailscale_executable do
    executable =
      case :os.type() do
        {:unix, :darwin} -> "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
        _ -> "tailscale"
      end

    case System.find_executable(executable) do
      nil -> raise TailscaleNotFound
      path -> path
    end
  end
end
