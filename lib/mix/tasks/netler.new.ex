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

  @supported_dotnet_versions ["net6.0", "net7.0", "net8.0", "net9.0", "net10.0"]
  @default_dotnet_version "net9.0"

  @impl true
  def run(_args) do
    dotnet_project =
      Mix.shell().prompt("Please give your .NET project a name:")
      |> String.trim()
      |> Macro.underscore()

    dotnet_version = prompt_dotnet_version()

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
          dotnet_project,
          dotnet_version
        )

        log_info(
          "Done! Remember to add :#{dotnet_project} to the dotnet_projects list in your application's mix.exs"
        )

        :ok
    end
  end

  defp prompt_dotnet_version do
    Mix.shell().info("Please select your .NET version:")

    @supported_dotnet_versions
    |> Enum.with_index(1)
    |> Enum.each(fn {version, index} ->
      default_marker = if version == @default_dotnet_version, do: " (default)", else: ""
      Mix.shell().info("  #{index}. #{version}#{default_marker}")
    end)

    input =
      Mix.shell().prompt("Enter number [1-#{length(@supported_dotnet_versions)}]:")
      |> String.trim()

    case input do
      "" ->
        @default_dotnet_version

      input ->
        case Integer.parse(input) do
          {n, ""} when n >= 1 and n <= length(@supported_dotnet_versions) ->
            Enum.at(@supported_dotnet_versions, n - 1)

          _ ->
            log_info("Invalid selection, defaulting to #{@default_dotnet_version}")
            @default_dotnet_version
        end
    end
  end

  defp create_source_files_from_templates(
         application_name,
         lib_path,
         project_path,
         dotnet_project,
         dotnet_version
       ) do
    File.mkdir_p!(project_path)
    csproj_file = "#{project_path}/#{Macro.camelize(dotnet_project)}.csproj"
    program_file = "#{project_path}/Program.cs"

    File.write!(csproj_file, csproj_template(dotnet_version))
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
      def subtract(a, b), do: invoke("Subtract", [a, b])
      def multiply(a, b), do: invoke("Multiply", [a, b])
      def divide(a, b), do: invoke("Divide", [a, b])
    end
    """
  end

  defp csproj_template(dotnet_version) do
    """
    <Project Sdk="Microsoft.NET.Sdk">

      <PropertyGroup>
          <OutputType>Exe</OutputType>
          <TargetFramework>#{dotnet_version}</TargetFramework>
      </PropertyGroup>

      <ItemGroup>
          <PackageReference Include="Netler.NET" Version="2.*" />
      </ItemGroup>

    </Project>
    """
  end

  defp program_template(dotnet_project) do
    """
    using System;
    using System.Threading.Tasks;
    using Netler;
    using Netler.Contracts;

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
                            // Example routes:
                            routes.AddTyped("Add", (int a, int b) => a + b);
                            routes.AddTyped("Subtract", (int a, int b) => a - b);
                            routes.AddTyped("Multiply", (int a, int b) => a * b);
                            routes.AddTyped("Divide", (int a, int b) => a / Convert.ToDouble(b));

                            // More routes can be added here ...
                        });
                    });

                await server.Start();
            }
        }
    }
    """
  end

  defp log_info(message) do
    Mix.shell().info([:blue, message])
  end

  defp log_error(message) do
    Mix.shell().info([:red, message])
  end
end
