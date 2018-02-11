defmodule FinancialSystem.Mixfile do
  use Mix.Project

  def project do
    [
      app: :financial_system,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
      ],
      test_coverage: [tool: ExCoveralls],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.5.7", only: :test},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
