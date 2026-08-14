defmodule PhoenixElixirE2E.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixElixirE2EWeb.Endpoint,
      {PhoenixElixirE2E.SyncWorker, base_url: "http://127.0.0.1:4051", bearer_token: "e2e-token"}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PhoenixElixirE2E.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhoenixElixirE2EWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
