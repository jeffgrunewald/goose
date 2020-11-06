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
      {:elli, "~> 3.3"},
      {:jason, "~> 1.2"},
      {:nimble_parsec, "~> 1.1", optional: true}
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Jeff Grunewald"],
      links: %{"GitHub" => @repo}
    }
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @repo,
      main: @name
    ]
  end
end