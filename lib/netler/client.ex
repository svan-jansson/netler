defmodule Netler.Client do
  @moduledoc false

  use GenServer

  alias Netler.Transport
  alias Netler.Message

  require Logger

  @invoke_timeout 60_000

  def child_spec(opts) do
    name = Keyword.get(opts, :name)

    %{
      id: name,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(name) do
    state = %{
      socket: nil,
      port: Transport.next_available_port()
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state = %{port: port}) do
    socket = connect(port)
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
end
