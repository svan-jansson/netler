defmodule Netler do
  def invoke(name, parameters) when is_list(parameters),
    do: Netler.Client.invoke(name, parameters)
end
