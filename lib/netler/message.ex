defmodule Netler.Message do
  @moduledoc false

  @doc "Encodes a message before sending it to a .NET application"
  def encode(data = %{}), do: Msgpax.pack(data)

  @doc "Decodes a message after receiving it from a .NET application"
  def decode(data) do
    with {:ok, decoded} <- Msgpax.unpack(data) do
      case decoded do
        [1 | [scalar]] -> {:ok, scalar}
        [0 | [scalar]] -> {:error, scalar}
        [1 | list] -> {:ok, list}
        [0 | list] -> {:error, list}
      end
    end
  end
end
