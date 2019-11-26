defmodule Netler.Compiler.Dotnet do
  def compile_netler(output_path) do
    System.cmd(
      "dotnet",
      ["build", "#{netler_source_path()}/Netler.csproj", "--output", output_path],
      into: IO.stream(:stdio, :line)
    )
  end

  def compile_project(project_name) do
    System.cmd(
      "dotnet",
      [
        "build",
        "#{project_path(project_name)}/#{Macro.camelize(project_name)}.csproj",
        "--output",
        project_build_binary_path(project_name)
      ],
      into: IO.stream(:stdio, :line)
    )
  end

  def project_path(project_name), do: Path.expand("dotnet/#{project_name}")
  def project_build_binary_path(project_name), do: Path.expand("priv/#{project_name}")
  def netler_source_path(), do: Path.join(Mix.Project.deps_path(), "netler/dotnet")

  def runtime_binary_path(project_name) do
    app = Mix.Project.config() |> Keyword.get(:app)
    Application.app_dir(app, "priv/#{project_name}")
  end
end
