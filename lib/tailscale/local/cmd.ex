defmodule Tailscale.Local.Cmd do
  alias Tailscale.Exceptions.{TailscaleCLIError, TailscaleNotFound, TailscaleNotRunning}

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
