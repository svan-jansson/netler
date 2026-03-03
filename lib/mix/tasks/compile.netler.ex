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
    if Mix.Project.umbrella?() do
      run_for_umbrella()
    else
      run_for_app()
    end
  end

  defp run_for_umbrella() do
    results =
      Mix.Project.apps_paths()
      |> Enum.map(fn {app, path} ->
        Mix.Project.in_project(app, path, [], fn _config ->
          run_for_app()
        end)
      end)

    cond do
      Enum.any?(results, &match?({:error, _}, &1)) -> {:error, []}
      Enum.any?(results, &match?({:ok, _}, &1)) -> {:ok, []}
      true -> {:noop, []}
    end
  end

  defp run_for_app() do
    config = Mix.Project.config()
    dotnet_projects = Keyword.get(config, :dotnet_projects, [])

    if dotnet_projects == [] do
      {:noop, []}
    else
      app_dir = app_root()
      priv_dir = Path.join(app_dir, "priv")
      File.mkdir_p!(priv_dir)

      ok? =
        dotnet_projects
        |> Enum.map(fn
          {project, _opts} -> Atom.to_string(project)
          project -> Atom.to_string(project)
        end)
        |> Enum.all?(fn project_name ->
          {_, exit_code} = File.cd!(app_dir, fn -> Dotnet.compile_project(project_name) end)
          exit_code == 0
        end)

      Mix.Utils.symlink_or_copy(
        priv_dir,
        Path.join(Mix.Project.app_path(config), "priv")
      )

      if ok?, do: {:ok, []}, else: {:error, []}
    end
  end

  defp app_root(), do: Mix.Project.project_file() |> Path.expand() |> Path.dirname()
end
