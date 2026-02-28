defmodule Netler.Mix.Tasks.Compile.NetlerTest do
  use ExUnit.Case

  test "returns :noop when no dotnet_projects are configured" do
    assert {:noop, []} == Mix.Tasks.Compile.Netler.run([])
  end
end
