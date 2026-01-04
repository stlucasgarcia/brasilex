defmodule Brasilex.MixProject do
  use Mix.Project

  @source_url "https://github.com/stlucasgarcia/brasilex"

  def project do
    [
      app: :brasilex,
      name: "Brasilex",
      version: "0.2.0",
      elixir: "~> 1.17",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      homepage_url: @source_url,
      deps: deps(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:decimal, "~> 2.0"},
      # {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp description do
    """
    Elixir library for Brazilian utilities and helpers.
    """
  end

  defp package do
    [
      maintainers: ["Lucas Garcia"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md usage_rules.md)
    ]
  end
end
