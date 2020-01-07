defmodule IBMCloud.MixProject do
  use Mix.Project

  @version "0.0.1-dev"

  def project do
    [
      app: :ibmcloud,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      licenses: ["Apache-2.0"],

      # ex_doc
      name: "IBMCloud",
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
      {:tesla, "~> 1.3"},
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
