defmodule Netler.Client do
  @moduledoc false

  use GenServer

  alias Netler.Transport
  alias Netler.Message

  require Logger

  @invoke_timeout 60_000

  def child_spec(opts) do
    project_name = Keyword.get(opts, :project_name)

    %{
      id: project_name,
      start: {__MODULE__, :start_link, [project_name]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(project_name) do
    state = %{
      project_name: project_name,
      socket: nil,
      port: Transport.next_available_port()
    }

    GenServer.start_link(__MODULE__, state, name: project_name)
  end

  def init(state = %{port: port, project_name: project_name}) do
    socket = connect(port)
    start_dotnet_server(project_name, port)
    {:ok, %{state | socket: socket}}
  end

  def invoke(project_name, method_name, parameters) do
    envelope = %{
      name: method_name,
      params: parameters
    }

    with {:ok, message} <- Message.encode(envelope),
         {:ok, response} <- GenServer.call(project_name, {:invoke, message}, @invoke_timeout) do
      Message.decode(response)
    end
  end

  def handle_call({:invoke, message}, _from, state = %{socket: socket}) when socket != nil do
    response =
      with :ok <- Transport.send(socket, message),
           {:ok, remote_response} = Transport.receive(socket) do
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

  def handle_info(:connect, state = %{port: port}) do
    socket = connect(port)
    {:noreply, %{state | socket: socket}}
  end

  defp connect(port) do
    with {:ok, socket} <- Transport.connect(port) do
      socket
    else
      {:error, _reason} ->
        Process.send_after(self(), :connect, 5_000)
        nil
    end
  end

  defp start_dotnet_server(project_name, port) do
    project_name = Atom.to_string(project_name)
    bin_path = Netler.Compiler.Dotnet.project_binary_path(project_name)
    project_file = Macro.camelize(project_name) <> ".dll"
    full_path = Path.join(bin_path, project_file)

    Task.Supervisor.start_child(Netler.DotnetProcessSupervisor, fn ->
      System.cmd("dotnet", [full_path, "#{port}"])
    end)
  end
end
