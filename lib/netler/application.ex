defmodule Netler.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Netler.Client
    ]

    opts = [strategy: :one_for_one, name: Netler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
