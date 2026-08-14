defmodule PhoenixElixirE2E.SyncWorker do
  @moduledoc """
  Supervised BEAM background worker that multiplexes independent HTTP lanes.

  Every wake owns an immutable lane batch. A transport or task failure replays
  the whole batch after bounded backoff; OptoSync reconciliation makes a lane
  that was applied before a lost response safe to send again.
  """

  use GenServer

  @default_attempts 8
  @default_retry_ms 100

  def start_link(options) do
    name = Keyword.get(options, :name, __MODULE__)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def drain(server \\ __MODULE__, lanes) when is_list(lanes) do
    GenServer.call(server, {:drain, lanes}, 30_000)
  end

  @impl true
  def init(options) do
    client =
      OptoSyncClient.new(
        Keyword.fetch!(options, :base_url),
        Keyword.get(options, :bearer_token)
      )

    {:ok,
     %{
       client: client,
       max_attempts: Keyword.get(options, :max_attempts, @default_attempts),
       retry_ms: Keyword.get(options, :retry_ms, @default_retry_ms)
     }}
  end

  @impl true
  def handle_call({:drain, lanes}, _from, state) do
    {:reply, drain_with_retry(lanes, state, 1), state}
  end

  defp drain_with_retry(lanes, state, attempt) do
    case drain_once(lanes, state.client) do
      {:ok, responses} ->
        {:ok, responses}

      {:error, _reason} when attempt < state.max_attempts ->
        Process.sleep(state.retry_ms)
        drain_with_retry(lanes, state, attempt + 1)

      {:error, reason} ->
        {:error, {:attempts_exhausted, state.max_attempts, reason}}
    end
  end

  defp drain_once(lanes, client) do
    lanes
    |> Task.async_stream(
      fn %{lane: lane, base: base, incoming: incoming} ->
        payload = Jason.encode!(%{base: base, incoming: incoming})

        request = {
          String.to_charlist(client.base_url <> "/api/merge"),
          authorization_headers(client.bearer_token),
          ~c"application/json",
          payload
        }

        case :httpc.request(:post, request, [], body_format: :binary) do
          {:ok, {{_, 200, _}, _headers, body}} -> {:ok, lane, Jason.decode!(body)}
          other -> {:error, lane, other}
        end
      end,
      ordered: false,
      timeout: 5_000
    )
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, {:ok, lane, response}}, {:ok, responses} ->
        {:cont, {:ok, [{lane, response} | responses]}}

      failure, _responses ->
        {:halt, {:error, failure}}
    end)
    |> case do
      {:ok, responses} -> {:ok, Enum.sort_by(responses, &elem(&1, 0))}
      error -> error
    end
  end

  defp authorization_headers(nil), do: []

  defp authorization_headers(token) do
    [{~c"authorization", String.to_charlist("Bearer " <> token)}]
  end
end
