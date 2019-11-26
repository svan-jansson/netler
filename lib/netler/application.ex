defmodule Netler.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    dotnet_projects =
      Mix.Project.config()
      |> Keyword.get(:dotnet_projects, [])

    children =
      Enum.map(dotnet_projects, fn project_name ->
        Netler.Client.child_spec(name: project_name)
      end)

    opts = [strategy: :one_for_one, name: Netler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
