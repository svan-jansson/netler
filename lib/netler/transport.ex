defmodule Netler.Transport do
  require Logger
  @moduledoc false

  @spec connect(non_neg_integer()) :: {:ok, :gen_tcp.socket()} | {:error, any()}
  @doc "Opens a socket on a given port"
  def connect(port), do: :gen_tcp.connect(~c"localhost", port, [:binary, active: false, packet: 4])

  @spec send(:gen_tcp.socket(), iodata()) :: :ok | {:error, any()}
  @doc "Sends a binary message to a socket stream"
  def send(socket, message), do: :gen_tcp.send(socket, message)

  @spec receive(:gen_tcp.socket()) :: {:ok, binary()} | {:error, any()}
  @doc "Receives a binary message from a socket stream"
  def receive(socket), do: :gen_tcp.recv(socket, 0)

  @spec next_available_port() :: non_neg_integer()
  @doc "Returns an available port that can be used for communicating with a .NET application"
  def next_available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    # NOTE: There is an inherent TOCTOU race between releasing this port and the
    # .NET server binding to it. Eliminating it would require the .NET side to
    # bind to port 0 and report back its chosen port number, which would need a
    # protocol change. The current risk is low in practice.
    :gen_tcp.close(port)
    port_number
  end
end
