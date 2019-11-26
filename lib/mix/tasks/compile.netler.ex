defmodule Mix.Tasks.Compile.Netler do
  use Mix.Task

  require Logger

  def run(_args) do
    IO.inspect(:code.priv_dir(:netler), label: "code.priv_dir")
    IO.inspect(:code.priv_dir(:netler), label: "code.lib_dir")
    IO.inspect(Path.expand("dotnet"), label: "expand")
    IO.inspect(Application.app_dir(:netler), label: "application app_dir")
    IO.inspect(Mix.Project.deps_path(), label: "deps path")

    :ok
  end

  defp compile_netler_dll() do
  end
end
