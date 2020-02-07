defmodule Koala.MixProject do
  use Mix.Project

  Application.put_env(:ed25519, :hash_fn, {Blake2, :hash2b, [], []})


  def project do
    [
      app: :koala,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :tesla, :tortoise, :ecto, :postgrex, :certifi],
      mod: {Koala.Application, []}
    ]
  end

  defp description() do
    "A nano wallet for Elixir applications"
  end
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tortoise, "~> 0.9.4"},
      {:ecto, "~> 2.2"},
      {:postgrex, "~> 0.13.5"},
      {:decimal, "~> 1.4"},
      {:blake2, "~> 1.0"},
      {:ed25519, "~> 1.1"},
      {:credo, "~> 0.8.8", only: :dev, runtime: false},
      {:tesla, "~> 1.2.0"},
      {:aes256, "~> 0.5.0"},
      {:jason, ">= 1.0.0"},
      {:calendar, "~> 1.0.0"},
      {:math, "~> 0.3.0"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
