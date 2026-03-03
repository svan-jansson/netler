defmodule Netler.InvokeError do
  @moduledoc false

  defexception [:communication_error, :dotnet_exception, :unreachable]

  def message(%{communication_error: communication_error}) when not is_nil(communication_error) do
    "Communication error: #{communication_error}"
  end

  def message(%{dotnet_exception: dotnet_exception}) when not is_nil(dotnet_exception) do
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

  @spec child_spec(keyword()) :: map()
  def child_spec(opts) do
    dotnet_project = Keyword.get(opts, :dotnet_project)
    app = Keyword.get(opts, :app)

    %{
      id: dotnet_project,
      start: {__MODULE__, :start_link, [dotnet_project, app, dotnet_project]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  @spec start_link(atom(), atom(), atom() | nil) :: GenServer.on_start()
  def start_link(dotnet_project, app, name \\ nil) do
    start_opts =
      case name do
        nil -> []
        name -> [name: name]
      end

    state = %{
      dotnet_project: dotnet_project,
      app: app,
      server: nil,
      port: nil,
      task_ref: nil
    }

    GenServer.start_link(__MODULE__, state, start_opts)
  end

  def init(state = %{dotnet_project: dotnet_project, app: app}) do
    port = Transport.next_available_port()
    task_ref = start_dotnet_server(dotnet_project, app, port)
    {:ok, %{state | port: port, task_ref: task_ref}, {:continue, :connect}}
  end

  def handle_continue(:connect, state = %{port: port}) do
    {:ok, server} = connect_to_server(port)
    {:noreply, %{state | server: server}}
  end

  @spec invoke(atom(), String.t(), list()) :: {:ok, any()} | {:error, any()}
  def invoke(dotnet_project, method_name, parameters) do
    envelope = %{
      name: method_name,
      params: parameters
    }

    with {:ok, message} <- Message.encode(envelope),
         {:ok, response} <- call(dotnet_project, {:invoke, message}) do
      Message.decode(response)
    end
  end

  def handle_call({:invoke, message}, _from, state = %{server: server}) when server != nil do
    response =
      with :ok <- Transport.send(server, message),
           {:ok, remote_response} <- Transport.receive(server) do
        {:ok, remote_response}
      else
        {:error, reason} ->
          {:error, %InvokeError{communication_error: reason}}

        unknown ->
          {:error, %InvokeError{communication_error: unknown}}
      end

    case response do
      {:error, _} = err -> {:reply, err, %{state | server: nil}}
      ok -> {:reply, ok, state}
    end
  end

  def handle_call({:invoke, _message}, _from, state) do
    {:reply, {:error, %InvokeError{unreachable: true}}, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{task_ref: ref} = state) do
    Logger.warning("Netler: .NET process terminated: #{inspect(reason)}")
    {:noreply, %{state | server: nil, task_ref: nil}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp call(server, message) do
    GenServer.call(server, message, @invoke_timeout)
  catch
    :exit, reason -> {:error, %InvokeError{communication_error: reason}}
  end

  defp connect_to_server(port) do
    max_attempts = 10
    current_attempt = 1
    connect(port, max_attempts, current_attempt)
  end

  defp connect(port, max_attempts, current_attempt) when current_attempt <= max_attempts do
    case Transport.connect(port) do
      {:ok, server} ->
        {:ok, server}

      {:error, _reason} ->
        Process.sleep(500)
        connect(port, max_attempts, current_attempt + 1)
    end
  end

  defp connect(_port, _max_attempts, _attempt), do: {:error, %InvokeError{unreachable: true}}

  defp start_dotnet_server(dotnet_project, app, port) do
    dotnet_project = Atom.to_string(dotnet_project)
    bin_path = Compiler.Dotnet.runtime_binary_path(dotnet_project, app)
    project_file = Macro.camelize(dotnet_project) <> ".dll"
    full_path = Path.join(bin_path, project_file)

    {:ok, pid} =
      Task.Supervisor.start_child(Netler.DotnetProcessSupervisor, fn ->
        System.cmd("dotnet", [full_path, "#{port}", System.pid()], cd: bin_path)
      end)

    Process.monitor(pid)
  end
end
