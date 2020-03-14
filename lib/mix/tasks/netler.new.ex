defmodule Mix.Tasks.Netler.New do
  @moduledoc """
  Creates a new embedded .NET project and an Elixir module for communicating with the .NET project

  ## Usage

  ```bash
  > mix netler.new
  ```
  """

  use Mix.Task
  alias Netler.Compiler.Dotnet

  @impl true
  def run(_args) do
    dotnet_project =
      Mix.Shell.IO.prompt("Please give your .NET project a name:")
      |> String.trim()
      |> Macro.underscore()

    case dotnet_project do
      "" ->
        log_error("Aborting: No project name given.")
        :error

      dotnet_project ->
        project_path = Dotnet.project_path(dotnet_project)

        app = Mix.Project.config() |> Keyword.get(:app)
        application_name = app |> Atom.to_string()
        lib_path = Path.expand("lib/#{application_name}")

        create_source_files_from_templates(
          application_name,
          lib_path,
          project_path,
          dotnet_project
        )

        log_info(
          "Done! Remeber to add :#{dotnet_project} to the dotnet_projects list in your application's mix.exs"
        )

        :ok
    end
  end

  defp create_source_files_from_templates(
         application_name,
         lib_path,
         project_path,
         dotnet_project
       ) do
    File.mkdir_p!(project_path)
    csproj_file = "#{project_path}/#{Macro.camelize(dotnet_project)}.csproj"
    program_file = "#{project_path}/Program.cs"

    File.write!(csproj_file, csproj_template())
    log_info("Created #{csproj_file}")

    File.write!(program_file, program_template(dotnet_project))
    log_info("Created #{program_file}")

    File.mkdir_p!(lib_path)
    ex_file = "#{lib_path}/#{dotnet_project}.ex"
    File.write!(ex_file, elixir_module_template(application_name, dotnet_project))
    log_info("Created #{ex_file}")
  end

  defp elixir_module_template(application_name, dotnet_project) do
    """
    defmodule #{Macro.camelize(application_name)}.#{Macro.camelize(dotnet_project)} do
      use Netler, dotnet_project: :#{dotnet_project}

      def add(a, b), do: invoke("Add", [a, b])
    end
    """
  end

  defp csproj_template do
    """
    <Project Sdk="Microsoft.NET.Sdk">

      <PropertyGroup>
          <OutputType>Exe</OutputType>
          <TargetFramework>netcoreapp3.1</TargetFramework>
      </PropertyGroup>

      <ItemGroup>
          <PackageReference Include="Netler.NET" Version="1.*" />
      </ItemGroup>

    </Project>
    """
  end

  defp program_template(dotnet_project) do
    """
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Netler;

    namespace #{Macro.camelize(dotnet_project)}
    {
        class Program
        {
            static async Task Main(string[] args)
            {
                var port = Convert.ToInt32(args[0]);
                var clientPid = Convert.ToInt32(args[1]);

                var server = Server.Create((config) =>
                    {
                        config.UsePort(port);
                        config.UseClientPid(clientPid);
                        config.UseRoutes((routes) =>
                        {
                            routes.Add("Add", Add);
                            // More routes can be added here ...
                        });
                    });

                await server.Start();
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
