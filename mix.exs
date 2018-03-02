defmodule JSONDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_diff,
      description: "An Elixir implementation of the diffing element of JSON Patch (RFC 6902)",
      version: "0.1.0",
      elixir: "~> 1.6",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Eddy Lane <naedin@gmail.com>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/EddyLane/elixir_json_diff",
        "Docs" => "https://hexdocs.pm/json_diff"
      }
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
      {:json_patch, "~> 0.8.0", only: :test}
    ]
  end
end