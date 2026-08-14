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

  test "the supervised background worker restarts and multiplexes independent lanes" do
    original = Process.whereis(PhoenixElixirE2E.SyncWorker)
    assert is_pid(original)
    Process.exit(original, :kill)
    replacement = await_replacement(original, 50)
    assert is_pid(replacement)

    lanes = [
      %{
        lane: "mobile-notifications",
        base: %{id: "doc-1", profile: %{server: "kept"}},
        incoming: %{profile: %{mobile: "background"}}
      },
      %{
        lane: "desktop-editor",
        base: %{id: "doc-2", profile: %{server: "kept"}},
        incoming: %{profile: %{desktop: "background"}}
      }
    ]

    assert {:ok, responses} = PhoenixElixirE2E.SyncWorker.drain(lanes)
    assert Enum.map(responses, &elem(&1, 0)) == ["desktop-editor", "mobile-notifications"]

    response_by_lane = Map.new(responses)

    assert response_by_lane["mobile-notifications"]["merged"]["profile"] == %{
             "mobile" => "background",
             "server" => "kept"
           }

    assert response_by_lane["desktop-editor"]["merged"]["profile"] == %{
             "desktop" => "background",
             "server" => "kept"
           }
  end

  defp await_replacement(_original, 0), do: nil

  defp await_replacement(original, attempts) do
    case Process.whereis(PhoenixElixirE2E.SyncWorker) do
      pid when is_pid(pid) and pid != original ->
        pid

      _ ->
        Process.sleep(20)
        await_replacement(original, attempts - 1)
    end
  end
end
