# Phoenix + Elixir Opto-Sync E2E

This repository proves the Opto-Sync boundary in a Phoenix application on the BEAM. A real HTTP request crosses Phoenix and Bandit, reaches the Rustler NIF, and reconciles data with the pinned `syncer.c` engine.

## What the test covers

- the official Elixir client constructs the service endpoint and authentication context;
- Phoenix parses and routes an actual JSON request over TCP;
- the official BEAM binding invokes `Syncer.merge!/3` with the shared CRDT policy;
- Rustler compiles the NIF through Rust into the pinned C core;
- nested objects and array elements matched by `id` preserve independent server and client fields;
- the response reports the native engine version.

`vendor/opto-sync-clients` is a Git submodule and includes the nested `syncer.c` submodule. `opto-sync-pin.json` makes both dependency revisions explicit.

## Run locally

Prerequisites: Elixir 1.14+, Erlang/OTP 25+, Rust/Cargo, and a C compiler.

```sh
git submodule update --init --recursive
mix local.hex --force
mix local.rebar --force
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

The included Dockerfile supplies all three toolchains when a local Elixir installation is unavailable.
