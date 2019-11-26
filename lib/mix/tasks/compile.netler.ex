defmodule Mix.Tasks.Compile.Netler do
  use Mix.Task

  alias Netler.Compiler.Dotnet

  def run(_args) do
    project_name =
      Mix.Project.config()
      |> Keyword.get(:dotnet_project)

    case project_name do
      nil ->
        Mix.Shell.IO.info([:red, "Project keyword `dotnet_project` missing in mix.exs"])
        :error

      project_name ->
        project_name = project_name |> Atom.to_string()
        project_path = Dotnet.project_path(project_name)
        Dotnet.compile_netler("#{project_path}/netler")
        Dotnet.compile_project(project_name)
        :ok
    end
  end
end
