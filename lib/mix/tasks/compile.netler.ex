defmodule Mix.Tasks.Compile.Netler do
  use Mix.Task

  alias Netler.Compiler.Dotnet

  def run(_args) do
    File.mkdir_p!("priv")
    config = Mix.Project.config()

    dotnet_projects =
      config
      |> Keyword.get(:dotnet_projects, [])

    dotnet_projects
    |> Enum.each(fn project_name ->
      project_name = project_name |> Atom.to_string()
      project_path = Dotnet.project_path(project_name)
      Dotnet.compile_netler("#{project_path}/netler")
      Dotnet.compile_project(project_name)
    end)

    symlink_or_copy(
      config,
      Path.expand("priv"),
      Path.join(Mix.Project.app_path(config), "priv")
    )

    :ok
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
