defmodule Maverick.MixProject do
  use Mix.Project

  @name "Maverick"
  @version "0.1.0"
  @repo "https://github.com/jeffgrunewald/maverick"

  def project do
    [
      app: :maverick,
      name: @name,
      version: @version,
      elixir: "~> 1.10",
      description: "Web API framework with a need for speed",
      homepage_url: @repo,
      source_url: @repo,
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.11"},
      {:jason, "~> 1.2"},
      {:nimble_parsec, "~> 1.1", optional: true},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:hackney, "~> 1.16", only: :test},
      {:plug_cowboy, "~> 2.4", only: :test},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Jeff Grunewald"],
      links: %{"GitHub" => @repo}
    }
  end

  defp docs do
    [
      logo: "assets/maverick-logo.png",
      source_ref: "v#{@version}",
      source_url: @repo,
      main: @name
    ]
  end
end
