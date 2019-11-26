defmodule Netler.Transport do
  @moduledoc false

  @doc "Opens a socket on a given port"
  def connect(port), do: :gen_tcp.connect('localhost', port, [:binary, active: false])

  @doc "Sends a binary message to a socket stream"
  def send(socket, message), do: :gen_tcp.send(socket, message)

  @doc "Receives a binary message from a socket stream"
  def receive(socket), do: :gen_tcp.recv(socket, 0)

  @doc "Returns an available port that can be used for communicating with a .NET application"
  def next_available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close(port)
    port_number
  end
end
