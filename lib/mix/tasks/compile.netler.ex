defmodule Mix.Tasks.Compile.Netler do
  @moduledoc """
  Compiles all embedded .NET projects listed in `dotnet_projects` in `mix.exs`.

  ## Usage

  In mix.exs:

  ```elixir
  def project do
    [
        app: :my_elixir_application,
        version: "0.1.0",
        elixir: "~> 1.9",
        start_permanent: Mix.env() == :prod,
        deps: deps(),
        compilers: Mix.compilers() ++ [:netler],
        dotnet_projects: [:my_dotnet_project]
    ]
  end
  ```
  """
  use Mix.Task

  alias Netler.Compiler.Dotnet

  @impl true
  def run(_args) do
    File.mkdir_p!("priv")
    config = Mix.Project.config()

    config
    |> Keyword.get(:dotnet_projects, [])
    |> Enum.each(&compile/1)

    symlink_or_copy(
      config,
      Path.expand("priv"),
      Path.join(Mix.Project.app_path(config), "priv")
    )

    :ok
  end

  defp compile({dotnet_project, _opts}), do: compile(dotnet_project)

  defp compile(dotnet_project) do
    dotnet_project = dotnet_project |> Atom.to_string()
    Dotnet.compile_project(dotnet_project)
  end

  defp symlink_or_copy(config, source, target) do
    if config[:build_embedded] do
      if File.exists?(source) do
        File.rm_rf!(target)
        File.cp_r!(source, target)
      end

      :ok
    else
      Mix.Utils.symlink_or_copy(source, target)
    end
  end
end
