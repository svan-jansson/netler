defmodule Netler do
  def invoke(project_name, method_name, parameters) when is_list(parameters),
    do: Netler.Client.invoke(project_name, method_name, parameters)
end
