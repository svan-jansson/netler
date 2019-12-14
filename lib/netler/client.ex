defmodule Netler.Client do
  @moduledoc false

  use GenServer

  alias Netler.{Compiler, Message, Transport}

  require Logger

  @invoke_timeout 60_000
  @sigterm [15]

  def child_spec(opts) do
    dotnet_project = Keyword.get(opts, :dotnet_project)

    %{
      id: dotnet_project,
      start: {__MODULE__, :start_link, [dotnet_project]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(dotnet_project) do
    state = %{
      dotnet_project: dotnet_project,
      socket: nil,
      port: nil
    }

    GenServer.start_link(__MODULE__, state, name: dotnet_project)
  end

  def init(state = %{port: port, dotnet_project: dotnet_project}) do
    Process.flag(:trap_exit, true)
    port = Transport.next_available_port()
    start_dotnet_server(dotnet_project, port)
    socket = connect(port)
    {:ok, %{state | socket: socket, port: port}}
  end

  def terminate(_reason, _state = %{socket: socket}) do
    Transport.send(socket, @sigterm)
    :normal
  end

  def invoke(dotnet_project, method_name, parameters) do
    envelope = %{
      name: method_name,
      params: parameters
    }

    with {:ok, message} <- Message.encode(envelope),
         {:ok, response} <- GenServer.call(dotnet_project, {:invoke, message}, @invoke_timeout) do
      Message.decode(response)
    end
  end

  def handle_call({:invoke, message}, _from, state = %{socket: socket}) when socket != nil do
    response =
      with :ok <- Transport.send(socket, message),
           {:ok, remote_response} <- Transport.receive(socket) do
        {:ok, remote_response}
      else
        {:error, error_details} -> {:error, error_details}
        unknown_error -> {:error, unknown_error}
      end

    {:reply, response, state}
  end

  def handle_call({:invoke, _message}, _from, state) do
    {:reply, {:error, ".NET server is unreachable"}, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  defp connect(port), do: connect(port, 1)

  defp connect(port, attempt) when attempt <= 10 do
    case Transport.connect(port) do
      {:ok, socket} ->
        socket

      {:error, _reason} ->
        Process.sleep(100)
        connect(port, attempt + 1)
    end
  end

  defp start_dotnet_server(dotnet_project, port) do
    dotnet_project = Atom.to_string(dotnet_project)
    bin_path = Compiler.Dotnet.runtime_binary_path(dotnet_project)
    project_file = Macro.camelize(dotnet_project) <> ".dll"
    full_path = Path.join(bin_path, project_file)

    Task.Supervisor.start_child(Netler.DotnetProcessSupervisor, fn ->
      System.cmd("dotnet", [full_path, "#{port}", System.pid()], cd: bin_path)
    end)
  end
end
