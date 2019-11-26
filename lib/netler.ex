defmodule Netler do
  defmacro __using__(opts) do
    quote do
      @dotnet_project Keyword.get(unquote(opts), :dotnet_project)

      def invoke(method_name, parameters),
        do: Netler.Client.invoke(@dotnet_project, method_name, parameters)

      def invoke!(method_name, parameters) do
        {:ok, response} = invoke(method_name, parameters)
        response
      end
    end
  end
end
