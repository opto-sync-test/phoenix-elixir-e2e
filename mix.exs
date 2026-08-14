defmodule PhoenixElixirE2E.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_elixir_e2e,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {PhoenixElixirE2E.Application, []},
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:opto_sync_client, path: "vendor/opto-sync-clients/clients/elixir"},
      {:opto_sync_nif, path: "vendor/opto-sync-clients/syncer.c/bindings/beam"},
      {:phoenix, "~> 1.7.21"}
    ]
  end
end
