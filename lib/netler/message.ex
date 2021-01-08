defmodule Netler.Message.DecodeError do
  @moduledoc false

  defexception [:message]

  def message(%{message: message}) do
    "Could not decode message from .NET server: #{message}"
  end
end

defmodule Netler.Message do
  @moduledoc false

  @server_ok 1
  @server_exception 0

  @doc "Encodes a message before sending it to a .NET application"
  def encode(data = %{}), do: Msgpax.pack(data)

  @doc "Decodes a message after receiving it from a .NET application"
  def decode(data) do
    case Msgpax.unpack(data) do
      {:ok, [@server_ok | [scalar]]} ->
        {:ok, scalar}

      {:ok, [@server_exception | [exception_details]]} ->
        {:error, exception_details}

      {:ok, [@server_ok | list]} ->
        {:ok, list}

      {:ok, [@server_exception | exception_details]} ->
        {:error, exception_details}

      {:error, decode_error} ->
        {:error, %Netler.Message.DecodeError{message: decode_error.reason}}
    end
  rescue
    other_error -> {:error, %Netler.Message.DecodeError{message: other_error.message}}
  end
end
