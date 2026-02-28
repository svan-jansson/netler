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

      results = Enum.map(dotnet_projects, &compile/1)

      Mix.Utils.symlink_or_copy(
        Path.expand("priv"),
        Path.join(Mix.Project.app_path(config), "priv")
      )

      if Enum.all?(results, &(&1 == :ok)) do
        {:ok, []}
      else
        {:error, []}
      end
    end
  end

  defp compile({dotnet_project, _opts}), do: compile(dotnet_project)

  defp compile(dotnet_project) do
    dotnet_project = dotnet_project |> Atom.to_string()
    Dotnet.compile_project(dotnet_project)
  end
end
