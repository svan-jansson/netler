defmodule Netler.Transport do
  @moduledoc false

  def connect(port), do: :gen_tcp.connect('localhost', port, [:binary, active: false])
  def send(socket, message), do: :gen_tcp.send(socket, message)
  def receive(socket), do: :gen_tcp.recv(socket, 0)

  def next_available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close(port)
    port_number
  end
end
