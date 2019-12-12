defmodule MessageTest do
  use ExUnit.Case
  alias Netler.Message

  test "encodes a message to binary format" do
    {:ok, dt, _} = DateTime.from_iso8601("2015-01-23T23:50:07Z")

    message = %{
      string: "string value",
      integer: 23,
      float: 34.66,
      datetime: dt
    }

    {atom, encoded} = Message.encode(message)
    assert atom == :ok
    assert is_list(encoded)
  end

  test "decodes a scalar message" do
    encoded = [146, [1], [23]]
    {atom, decoded} = Message.decode(encoded)
    assert atom == :ok
    assert decoded == 23
  end

  test "decodes a list message" do
    encoded = [146, [1], [148, [23], [22], [21], [20]]]
    {atom, decoded} = Message.decode(encoded)
    assert atom == :ok
    assert decoded == [23, 22, 21, 20]
  end

  test "unpacks error status from message" do
    encoded = [146, [0], [23]]
    {atom, decoded} = Message.decode(encoded)
    assert atom == :error
    assert decoded == 23
  end
end
