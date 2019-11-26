defmodule Mix.Tasks.Compile.Netler do
  use Mix.Task

  require Logger

  def run(_args) do
    dotnet_path = Path.join(Mix.Project.deps_path(), "netler/dotnet")
    :ok
  end

  defp compile_netler_dll() do
  end
end
