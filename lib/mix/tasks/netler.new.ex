defmodule Mix.Tasks.Netler.New do
  use Mix.Task

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
        project_path = "priv/dotnet/#{project_name}"
        create_dotnet_project(project_path, project_name)

        netler_source_path = Path.join(Mix.Project.deps_path(), "netler/dotnet")
        build_netler_dll(netler_source_path, project_path)
        Mix.Shell.IO.info([:green, "Created new .NET project in #{project_path}"])
        :ok
    end
  end

  defp build_netler_dll(netler_source_path, project_path) do
    System.cmd(
      "dotnet",
      ["#{netler_source_path}/Netler.csproj", "--output", "#{project_path}/netler"],
      into: IO.stream(:stdio, :line)
    )
  end

  defp create_dotnet_project(project_path, project_name) do
    File.mkdir_p!(project_path)
    csproj_file = "#{project_path}/#{Macro.camelize(project_name)}.csproj"
    program_file = "#{project_path}/Program.cs"

    File.write!(csproj_file, csproj_template())
    File.write!(program_file, program_template(project_name))
  end

  defp csproj_template() do
    """
    <Project Sdk="Microsoft.NET.Sdk">

        <PropertyGroup>
            <OutputType>Exe</OutputType>
            <TargetFramework>netcoreapp3.0</TargetFramework>
        </PropertyGroup>

        <ItemGroup>
            <Reference Include="Netler">
                <HintPath>netler/Netler.dll</HintPath>
            </Reference>
        </ItemGroup>

    </Project>
    """
  end

  defp program_template(project_name) do
    """
    using System;
    using System.Collections.Generic;
    using Netler;

    namespace #{Macro.camelize(project_name)}
    {
        class Program
        {
            static void Main(string[] args)
            {
                Netler.Server.Export(
                    args,
                    new Dictionary<string, Func<object[], object>> {
                        {"Add", Add}
                    }
                );
            }

            static object Add(params object[] parameters)
            {
                var a = Convert.ToInt32(parameters[0]);
                var b = Convert.ToInt32(parameters[1]);
                return a + b;
            }
        }
    }
    """
  end
end
