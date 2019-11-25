defmodule Netler.Client do
  @moduledoc false

  use GenServer

  alias Netler.Transport
  alias Netler.Message

  require Logger

  def start_link(_opts) do
    state = %{
      socket: nil,
      port: Transport.next_available_port()
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state = %{port: port}) do
    socket = connect(port)
    {:ok, %{state | socket: socket}}
  end

  def invoke(method_name, method_params) do
    message =
      Message.encode(%{
        name: method_name,
        params: method_params
      })

    response = GenServer.call(__MODULE__, {:invoke, message})

    Message.decode(response)
  end

  def handle_call({:invoke, message}, _from, state = %{socket: socket}) do
    response =
      with :ok <- Transport.send(socket, message),
           {:ok, remote_response} = Transport.receive(socket) do
        remote_response
      else
        {:error, error_details} -> error_details
        unknown_error -> unknown_error
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
