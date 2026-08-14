defmodule PhoenixElixirE2EWeb.Router do
  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", PhoenixElixirE2EWeb do
    pipe_through(:api)

    get("/health", SyncController, :health)
    post("/merge", SyncController, :merge)
  end
end
