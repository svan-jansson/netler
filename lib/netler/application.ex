defmodule Netler.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    dotnet_projects =
      Mix.Project.config()
      |> Keyword.get(:dotnet_projects, [])

    default_children = [{Task.Supervisor, name: Netler.DotnetProcessSupervisor}]

    children =
      Enum.reduce(dotnet_projects, default_children, fn
        {dotnet_project, opts}, acc ->
          case Keyword.get(opts, :autostart, true) do
            true -> [Netler.Client.child_spec(dotnet_project: dotnet_project) | acc]
            false -> acc
          end

        dotnet_project, acc ->
          [Netler.Client.child_spec(dotnet_project: dotnet_project) | acc]
      end)

    opts = [strategy: :one_for_one, name: Netler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
