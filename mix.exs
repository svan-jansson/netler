defmodule Netler.MixProject do
  use Mix.Project

  def project do
    [
      app: :netler,
      name: "Netler",
      source_url: "https://github.com/svan-jansson/netler",
      version: "0.0.0-dev",
      elixir: "~> 1.15",
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
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:msgpax, "~> 2.4"}
    ]
  end

  defp description do
    """
    Enables language interoperability between Elixir and .NET
    """
  end

  defp package do
    [
      maintainers: ["Svan Jansson"],
      licenses: ["MIT"],
      links: %{Github: "https://github.com/svan-jansson/netler"},
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*)
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
