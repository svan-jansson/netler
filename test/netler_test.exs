defmodule NetlerTest do
  use ExUnit.Case
  doctest Netler

  test "greets the world" do
    assert Netler.hello() == :world
  end
end
