defmodule PhoenixElixirE2EWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_elixir_e2e

  plug(Plug.RequestId)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(PhoenixElixirE2EWeb.Router)
end
