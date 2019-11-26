defmodule Netler.Message do
  @moduledoc false

  @doc "Encodes a message before sending it to a .NET application"
  def encode(data = %{}), do: Msgpax.pack(data)

  @doc "Decodes a message after receiving it from a .NET application"
  def decode(data) do
    with {:ok, [atom | message]} <- Msgpax.unpack(data) do
      case atom do
        1 -> {:ok, message}
        0 -> {:error, message}
      end
    end
  end
end
