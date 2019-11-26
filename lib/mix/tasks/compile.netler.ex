defmodule Mix.Tasks.Compile.Netler do
  use Mix.Task

  alias Netler.Compiler.Dotnet

  def run(_args) do
    dotnet_projects =
      Mix.Project.config()
      |> Keyword.get(:dotnet_project, [])

    dotnet_projects
    |> Enum.each(fn project_name ->
      project_name = project_name |> Atom.to_string()
      project_path = Dotnet.project_path(project_name)
      Dotnet.compile_netler("#{project_path}/netler")
      Dotnet.compile_project(project_name)
    end)

    :ok
  end
end
