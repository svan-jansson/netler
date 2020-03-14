defmodule Netler.Compiler.Dotnet do
  @moduledoc false

  @doc "Compiles an embedded .NET project into the priv/<dotnet_project> folder"
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

  @doc "Returns the source code path for an embedded .NET project"
  def project_path(dotnet_project), do: Path.expand("dotnet/#{dotnet_project}")

  @doc "Returns the path to where the binaries are located after building an embedded .NET project"
  def project_build_binary_path(dotnet_project), do: Path.expand("priv/#{dotnet_project}")

  @doc "Returns the path to where the an embedded .NET project's binaries are located during runtime"
  def runtime_binary_path(dotnet_project) do
    app = Mix.Project.config() |> Keyword.get(:app)
    Application.app_dir(app, "priv/#{dotnet_project}")
  end
end
