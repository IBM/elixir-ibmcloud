defmodule IBMCloud.MixProject do
  use Mix.Project

  @version "0.0.2-dev"

  def project do
    [
      app: :ibmcloud,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],

      # hex
      description: "Thin wrapper for IBM Cloud API",
      package: package(),

      # ex_doc
      name: "IBMCloud",
      source_url: "https://github.com/IBM/elixir-ibmcloud",
      homepage_url: "https://github.com/IBM/elixir-ibmcloud",
      docs: [main: "IBMCloud"]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:jose, "~> 1.10"},
      {:tesla, "~> 1.4"},
      {:uri_query, "~> 0.1.1"},
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:faker, "~> 0.17", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/IBM/elixir-ibmcloud"
      }
    ]
  end
end
