import Config

config :phoenix_elixir_e2e, PhoenixElixirE2EWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4051],
  secret_key_base: String.duplicate("opto-sync-e2e-", 8),
  server: true,
  url: [host: "127.0.0.1", port: 4051]

config :phoenix, :json_library, Jason

config :logger, level: :warning
