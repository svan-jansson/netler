defmodule Netler.InvokeError do
  @moduledoc false

  defexception [:communication_error, :dotnet_exception, :unreachable]

  def message(%{communication_error: communication_error}) do
    "Communication error: #{communication_error}"
  end

  def message(%{dotnet_exception: dotnet_exception}) do
    ".NET server threw an exception: #{dotnet_exception}"
  end

  def message(%{unreachable: true}) do
    ".NET server is unreachable"
  end
end

defmodule Netler.Client do
  @moduledoc false

  use GenServer

  alias Netler.{Compiler, InvokeError, Message, Transport}

  require Logger

  @invoke_timeout 60_000

  def child_spec(opts) do
    dotnet_project = Keyword.get(opts, :dotnet_project)

    %{
      id: dotnet_project,
      start: {__MODULE__, :start_link, [dotnet_project, dotnet_project]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(dotnet_project, name \\ nil) do
    start_opts =
      case name do
        nil -> []
        name -> [name: name]
      end

    state = %{
      dotnet_project: dotnet_project,
      socket: nil,
      port: nil
    }

    GenServer.start_link(__MODULE__, state, start_opts)
  end

  def init(state = %{dotnet_project: dotnet_project}) do
    port = Transport.next_available_port()
    start_dotnet_server(dotnet_project, port)
    {:ok, socket} = connect(port)
    {:ok, %{state | socket: socket, port: port}}
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
        {:error, dotnet_exception} -> {:error, %InvokeError{dotnet_exception: dotnet_exception}}
        unknown_error -> {:error, %InvokeError{communication_error: unknown_error}}
      end

    {:reply, response, state}
  end

  def handle_call({:invoke, _message}, _from, state) do
    {:reply, {:error, %InvokeError{unreachable: true}}, state}
  end

  defp connect(port), do: connect(port, 1)

  defp connect(port, attempt) when attempt <= 10 do
    case Transport.connect(port) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, _reason} ->
        Process.sleep(500)
        connect(port, attempt + 1)
    end
  end

  defp connect(_port, _attempt), do: {:error, %InvokeError{unreachable: true}}

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
