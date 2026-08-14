defmodule PhoenixElixirE2E.PhoenixSyncTest do
  use ExUnit.Case, async: false

  test "the official Elixir client crosses Phoenix and merges through the NIF" do
    client = OptoSyncClient.new("http://127.0.0.1:4051", "e2e-token")
    assert client.bearer_token == "e2e-token"

    payload =
      Jason.encode!(%{
        base: %{
          id: "doc-1",
          profile: %{server: "kept"},
          items: [%{id: "a", server: true}]
        },
        incoming: %{
          profile: %{client: "kept"},
          items: [%{id: "a", client: true}]
        }
      })

    request = {
      String.to_charlist(client.base_url <> "/api/merge"),
      [{~c"authorization", ~c"Bearer e2e-token"}],
      ~c"application/json",
      payload
    }

    assert {:ok, {{_, 200, _}, _headers, body}} =
             :httpc.request(:post, request, [], body_format: :binary)

    response = Jason.decode!(body)
    assert response["coreVersion"] =~ ~r/^\d+\.\d+\.\d+$/
    assert response["merged"]["profile"] == %{"client" => "kept", "server" => "kept"}
    assert response["merged"]["items"] == [%{"client" => true, "id" => "a", "server" => true}]
  end
end
