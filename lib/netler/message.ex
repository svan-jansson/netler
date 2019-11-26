defmodule Netler.Message do
  def encode(data = %{}), do: Msgpax.pack(data)
  def decode(data), do: Msgpax.unpack(data)
end
