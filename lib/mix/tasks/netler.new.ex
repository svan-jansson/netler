defmodule Mix.Tasks.Netler.New do
  use Mix.Task
  alias Netler.Compiler.Dotnet

  def run(_args) do
    project_name =
      Mix.Shell.IO.prompt("Please give your .NET project a name:")
      |> String.trim()
      |> Macro.underscore()

    case project_name do
      "" ->
        log_error("Aborting: No project name given.")
        :error

      project_name ->
        project_path = Dotnet.project_path(project_name)

        app = Mix.Project.config() |> Keyword.get(:app)
        application_name = app |> Atom.to_string()
        lib_path = "lib/#{application_name}"

        create_source_files_from_templates(application_name, lib_path, project_path, project_name)

        Dotnet.compile_netler("#{project_path}/netler")

        log_info(
          "Done! Remeber to add :#{project_name} to the dotnet_projects list in your application's mix.exs"
        )

        :ok
    end
  end

  defp create_source_files_from_templates(application_name, lib_path, project_path, project_name) do
    File.mkdir_p!(project_path)
    csproj_file = "#{project_path}/#{Macro.camelize(project_name)}.csproj"
    program_file = "#{project_path}/Program.cs"

    File.write!(csproj_file, csproj_template())
    log_info("Created #{csproj_file}")

    File.write!(program_file, program_template(project_name))
    log_info("Created #{program_file}")

    File.mkdir_p!(lib_path)
    ex_file = "#{lib_path}/#{project_name}.ex"
    File.write!(ex_file, elixir_module_template(application_name, project_name))
    log_info("Created #{ex_file}")
  end

  defp elixir_module_template(application_name, project_name) do
    """
    defmodule #{Macro.camelize(application_name)}.#{Macro.camelize(project_name)} do
      use Netler, dotnet_project: :#{project_name}

      def add(a, b), do: invoke("Add", [a, b])
    end
    """
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

  defp log_info(message) do
    Mix.Shell.IO.info([:blue, message])
  end

  defp log_error(message) do
    Mix.Shell.IO.info([:red, message])
  end
end
