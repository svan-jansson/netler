# Agent Guidance for netler

## Project Overview

`netler` is an Elixir library that enables language interoperability between Elixir and .NET via TCP + MessagePack. It mirrors the design of [Rustler](https://github.com/rusterlium/rustler): a Mix task scaffolds an embedded .NET project and a companion Elixir module; at runtime the Elixir side spawns the .NET process and communicates with it over a local TCP socket using MessagePack-encoded messages.

## Repository Layout

```
lib/
  netler.ex                        # Public API macro (__using__)
  netler/
    application.ex                 # OTP Application + supervision tree
    client.ex                      # GenServer per .NET project (+ InvokeError)
    message.ex                     # MessagePack encode/decode (+ DecodeError)
    transport.ex                   # :gen_tcp helpers
  compiler/
    dotnet.ex                      # Path helpers + dotnet build wrapper
  mix/tasks/
    compile.netler.ex              # Mix compiler task
    netler.new.ex                  # Mix scaffold task
test/
  message_test.exs                 # Pure-Elixir unit tests (no .NET SDK needed)
  test_helper.exs
```

## Build & Test Commands

```bash
mix deps.get
mix compile --warnings-as-errors
mix credo
mix test
mix docs
```

> **Note:** `mix test` runs only pure-Elixir tests. End-to-end tests (spawning a real .NET server) require the .NET 9 SDK to be installed and are not part of the automated CI suite.

## CI/CD Overview

GitHub Actions workflow: `.github/workflows/build-test-publish.yml`

- **build job** — runs on every push and PR:
  - Installs Erlang + Elixir via `mise` (versions pinned in `mise.toml`)
  - `mix deps.get` → `mix compile --warnings-as-errors` → `mix test` → `mix credo`
- **publish job** — runs on `master` push only, after `build` passes:
  - Computes a semver from `VERSION` (major.minor) + commit-height patch
  - Patches `mix.exs` version string in-place
  - Publishes to Hex.pm (`HEX_API_KEY` secret required in repo settings)
  - Creates a GitHub release with auto-generated notes

## Key Conventions

- **Elixir version**: `~> 1.15` minimum (use `~c"..."` charlist syntax, not `'...'`)
- **.NET target framework**: `net9.0` in generated `.csproj` templates
- **OTP/Elixir pins**: see `mise.toml` (Erlang 28, Elixir 1.19.5-OTP-28)
- **Deps**: `msgpax ~> 2.4`, `credo ~> 1.7`, `ex_doc ~> 0.40`
- **@spec**: all public functions in `Netler.*` modules should carry `@spec` annotations
- **Module naming**: test modules use full namespace (`Netler.MessageTest`, etc.)

## What Requires .NET SDK

| Task | Needs .NET SDK? |
|---|---|
| `mix test` (message unit tests) | No |
| `mix netler.new` (scaffold) | No (just writes files) |
| `mix compile` (Netler compiler step) | Yes (calls `dotnet build`) |
| Running the application end-to-end | Yes |

When modifying `.csproj` templates or `Program.cs` templates in `netler.new.ex`, validate manually with a .NET 9 SDK if available.
