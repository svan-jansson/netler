defmodule Netler.MixProject do
  use Mix.Project

  def project do
    [
      app: :netler,
      name: "Netler",
      source_url: "https://github.com/svan-jansson/netler",
      version: "0.1.5",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Netler.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:msgpax, "~> 2.0"}
    ]
  end

  defp description do
    """
    Enables language interopablility between Elixir and .NET
    """
  end

  defp package do
    [
      maintainers: ["Svan Jansson"],
      licenses: ["MIT"],
      links: %{Github: "https://github.com/svan-jansson/netler"},
      files: ~w(lib dotnet/*.cs dotnet/*.csproj .formatter.exs mix.exs README* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      logo: "logo/netler.svg.png"
    ]
  end
end
