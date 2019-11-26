defmodule Netler.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    dotnet_projects =
      Mix.Project.config()
      |> Keyword.get(:dotnet_projects, [])

    children =
      Enum.map(dotnet_projects, fn dotnet_project ->
        Netler.Client.child_spec(dotnet_project: dotnet_project)
      end)

    children = [{Task.Supervisor, name: Netler.DotnetProcessSupervisor} | children]
    opts = [strategy: :one_for_one, name: Netler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
