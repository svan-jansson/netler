defmodule Netler.Compiler.Dotnet do
  def compile_netler(output_path) do
    System.cmd(
      "dotnet",
      ["build", "#{netler_source_path()}/Netler.csproj", "--output", output_path],
      into: IO.stream(:stdio, :line)
    )
  end

  def compile_project(dotnet_project) do
    System.cmd(
      "dotnet",
      [
        "build",
        "#{project_path(dotnet_project)}/#{Macro.camelize(dotnet_project)}.csproj",
        "--output",
        project_build_binary_path(dotnet_project)
      ],
      into: IO.stream(:stdio, :line)
    )
  end

  def project_path(dotnet_project), do: Path.expand("dotnet/#{dotnet_project}")
  def project_build_binary_path(dotnet_project), do: Path.expand("priv/#{dotnet_project}")
  def netler_source_path(), do: Path.join(Mix.Project.deps_path(), "netler/dotnet")

  def runtime_binary_path(dotnet_project) do
    app = Mix.Project.config() |> Keyword.get(:app)
    Application.app_dir(app, "priv/#{dotnet_project}")
  end
end
