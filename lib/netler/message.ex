defmodule Netler.Message.DecodeError do
  @moduledoc false

  defexception [:message]

  def message(%{message: message}) do
    "Could not decode message from .NET server: #{message}"
  end
end

defmodule Netler.Message do
  @moduledoc false

  @doc "Encodes a message before sending it to a .NET application"
  def encode(data = %{}), do: Msgpax.pack(data)

  @doc "Decodes a message after receiving it from a .NET application"
  def decode(data) do
    case Msgpax.unpack(data) do
      {:ok, [1 | [scalar]]} ->
        {:ok, scalar}

      {:ok, [0 | [scalar]]} ->
        {:error, scalar}

      {:ok, [1 | list]} ->
        {:ok, list}

      {:ok, [0 | list]} ->
        {:error, list}

      {:error, decode_error} ->
        {:error, %Netler.Message.DecodeError{message: decode_error.reason}}
    end
  rescue
    error -> {:error, %Netler.Message.DecodeError{message: error.message}}
  end
end
