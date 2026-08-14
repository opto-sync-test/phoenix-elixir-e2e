defmodule PhoenixElixirE2EWeb.SyncController do
  use Phoenix.Controller, formats: [:json]

  def health(conn, _params) do
    json(conn, %{status: "ok", coreVersion: Syncer.version()})
  end

  def merge(conn, %{"base" => base, "incoming" => incoming}) do
    merged_json =
      Syncer.merge!(
        Jason.encode!(base),
        Jason.encode!(incoming),
        Syncer.crdt_options()
      )

    json(conn, %{
      merged: Jason.decode!(merged_json),
      coreVersion: Syncer.version()
    })
  end
end
