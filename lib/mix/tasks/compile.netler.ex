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
        elixir: "~> 1.15",
        start_permanent: Mix.env() == :prod,
        deps: deps(),
        compilers: Mix.compilers() ++ [:netler],
        dotnet_projects: [:my_dotnet_project]
    ]
  end
  ```
  """
  use Mix.Task.Compiler

  alias Netler.Compiler.Dotnet

  @impl Mix.Task.Compiler
  def run(_args) do
    config = Mix.Project.config()
    dotnet_projects = Keyword.get(config, :dotnet_projects, [])

    if dotnet_projects == [] do
      {:noop, []}
    else
      File.mkdir_p!("priv")

      ok? =
        dotnet_projects
        |> Enum.map(fn
          {project, _opts} -> Atom.to_string(project)
          project -> Atom.to_string(project)
        end)
        |> Enum.all?(fn project_name ->
          {_, exit_code} = Dotnet.compile_project(project_name)
          exit_code == 0
        end)

      Mix.Utils.symlink_or_copy(
        Path.expand("priv"),
        Path.join(Mix.Project.app_path(config), "priv")
      )

      if ok?, do: {:ok, []}, else: {:error, []}
    end
  end
end
