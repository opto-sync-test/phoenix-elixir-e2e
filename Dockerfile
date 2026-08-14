FROM rust:1.97-slim AS test

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    elixir \
    erlang-dev \
    erlang-inets \
    erlang-ssl \
    git

ENV MIX_HOME=/opt/mix \
    HEX_HOME=/opt/hex

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app
COPY . .
RUN mix deps.get
RUN mix compile --warnings-as-errors

CMD ["mix", "test"]
