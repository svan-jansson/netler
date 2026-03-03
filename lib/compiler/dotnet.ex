defmodule Netler.Compiler.Dotnet do
  @moduledoc false

  @spec compile_project(String.t()) :: {Collectable.t(), exit_status :: non_neg_integer()}
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

  @spec project_path(String.t()) :: String.t()
  @doc "Returns the source code path for an embedded .NET project"
  def project_path(dotnet_project), do: Path.expand("dotnet/#{dotnet_project}")

  @spec project_build_binary_path(String.t()) :: String.t()
  @doc "Returns the path to where the binaries are located after building an embedded .NET project"
  def project_build_binary_path(dotnet_project), do: Path.expand("priv/#{dotnet_project}")

  @spec runtime_binary_path(String.t(), atom()) :: String.t()
  @doc "Returns the path to where the an embedded .NET project's binaries are located during runtime"
  def runtime_binary_path(dotnet_project, app) do
    Application.app_dir(app, "priv/#{dotnet_project}")
  end
end
