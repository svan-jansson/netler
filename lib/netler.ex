defmodule Netler do
  @moduledoc """
  API module for interop with embedded .NET projects

  ## Usage

  ```elixir
  defmodule MyElixirApplication.MyDotnetProject do

    # This links a module to a specific .NET project
    use Netler, dotnet_project: :my_dotnet_project

    # Use invoke/2 or invoke!/2 to route a message to
    # an exported .NET method
    def add(a, b), do: invoke("Add", [a, b])
  end
  ```

  """

  defmacro __using__(opts) do
    quote do
      @dotnet_project Keyword.get(unquote(opts), :dotnet_project)

      @doc "Invokes a named method in the linked .NET project. Returns `{:ok, response}` or `{:error, reason}`"
      def invoke(method_name, parameters),
        do: Netler.Client.invoke(@dotnet_project, method_name, parameters)

      @doc "Same as `invoke/2` but raises errors"
      def invoke!(method_name, parameters) do
        case invoke(method_name, parameters) do
          {:ok, response} -> response
          {:error, reason} -> raise reason
        end
      end
    end
  end
end
