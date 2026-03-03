defmodule Netler.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    dotnet_config =
      if Code.ensure_loaded?(Mix) do
        if Mix.Project.umbrella?() do
          Mix.Project.apps_paths()
          |> Enum.flat_map(fn {app, path} ->
            Mix.Project.in_project(app, path, [], fn _module ->
              Mix.Project.config() |> Keyword.get(:dotnet_projects, []) |> Enum.map(&{&1, app})
            end)
          end)
        else
          config = Mix.Project.config()
          app = Keyword.get(config, :app)
          config |> Keyword.get(:dotnet_projects, []) |> Enum.map(&{&1, app})
        end
      else
        app = Application.get_env(:netler, :app)
        Application.get_env(:netler, :dotnet_projects, []) |> Enum.map(&{&1, app})
      end

    children =
      Enum.reduce(dotnet_config, [], fn
        {{dotnet_project, opts}, app}, acc ->
          case Keyword.get(opts, :autostart, true) do
            true -> [Netler.Client.child_spec(dotnet_project: dotnet_project, app: app) | acc]
            false -> acc
          end

        {dotnet_project, app}, acc ->
          [Netler.Client.child_spec(dotnet_project: dotnet_project, app: app) | acc]
      end)

    children = [{Task.Supervisor, name: Netler.DotnetProcessSupervisor} | children]

    opts = [strategy: :one_for_one, name: Netler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
