# OpenCode A2A Server (Windows)

A ready-to-run [OpenCode](https://opencode.ai) A2A (Agent-to-Agent) server setup for
Windows 11 + PowerShell, built on the
[Intelligent-Internet/opencode-a2a](https://github.com/Intelligent-Internet/opencode-a2a)
Python sidecar. Smoke-tested end-to-end (7/7 checks pass) on OpenCode 1.18.4.

It lets remote A2A peers call your local OpenCode runtime over the A2A 1.0 protocol:
Agent Card discovery, authenticated message send, SSE streaming, task retrieval,
session continuity, and cancellation.

## Architecture

```
opencode serve (127.0.0.1:4096)
        ↑ OPENCODE_BASE_URL
opencode-a2a serve (127.0.0.1:8000)
  ├── Agent Card:  http://127.0.0.1:8000/.well-known/agent-card.json
  ├── REST:        POST /v1/message:send, /v1/message:stream
  └── JSON-RPC:    POST /  (SendMessage, GetTask, CancelTask, ...)
```

The sidecar talks to the local `opencode serve` HTTP API; remote peers talk to the
sidecar. Loopback-only by default.

## Prerequisites

- Windows 11, PowerShell 5.1+
- [OpenCode](https://opencode.ai) ≥ 1.18 (`bun install -g opencode-ai`), with at
  least one authenticated provider (`opencode auth login`)
- [uv](https://docs.astral.sh/uv/) (installs Python automatically)
- git

## Quick start

```powershell
# 1. Install the A2A sidecar
uv tool install opencode-a2a

# 2. Generate credentials (User scope, persistent). Values are NOT printed.
powershell -File scripts\setup-a2a-env.ps1

# 3. Start both services (background jobs)
powershell -File scripts\start-a2a.ps1

# 4. Verify
curl http://127.0.0.1:8000/.well-known/agent-card.json
powershell -File scripts\test-a2a-smoke.ps1    # full 7-check smoke test

# Stop
powershell -File scripts\stop-a2a.ps1
```

Restart any open shells after step 2 so they pick up the new User-scope variables.

> **PowerShell note:** `start-a2a.ps1` uses background **jobs**, which live only as
> long as the PowerShell session that started them. Run `start-a2a.ps1` and
> `test-a2a-smoke.ps1` in the **same** shell, and keep it open while using the
> server (or run `opencode serve` / `opencode-a2a serve` in two dedicated
> terminals instead). `stop-a2a.ps1` only works in the session that started the
> jobs.

## Environment variables

| Variable | Scope | Purpose |
|---|---|---|
| `A2A_STATIC_AUTH_CREDENTIALS` | User | JSON array of accepted inbound credentials (bearer + principal) |
| `A2A_CLIENT_BEARER_TOKEN` | User | Token used for outbound `a2a_call` to peers |
| `A2A_HOST` / `A2A_PORT` | optional | Bind address (default `127.0.0.1:8000`) |
| `OPENCODE_BASE_URL` | optional | Upstream opencode serve (default `http://127.0.0.1:4096`) |
| `A2A_TASK_STORE_BACKEND` | optional | `database` (default, durable SQLite) or `memory` |

**Important (verified):** do **NOT** set `OPENCODE_SERVER_PASSWORD` for this local
loopback setup — the sidecar's upstream client cannot authenticate to a
password-protected `opencode serve`. The security boundary is loopback binding +
A2A bearer auth on port 8000.

## Protocol notes (verified 2026-08-03, A2A 1.0)

- REST payload roles: `ROLE_USER` / `ROLE_AGENT`; parts use direct fields
  (`{"text": "..."}`, no `kind` wrapper).
- JSON-RPC methods are PascalCase: `SendMessage`, `SendStreamingMessage`,
  `GetTask`, `ListTasks`, `CancelTask`, `SubscribeToTask`, plus OpenCode extensions
  (`opencode.sessions.*`, `opencode.providers.list`, `opencode.models.list`).
- Task states: `TASK_STATE_COMPLETED`, `TASK_STATE_CANCELED`, ...
- On Windows PowerShell, set `$env:PYTHONIOENCODING='utf-8'` before running
  `opencode-a2a` (its banner crashes on cp1252 consoles otherwise).

## Security

- Loopback-only binding; do not expose beyond `127.0.0.1` without TLS + auth.
- Bearer/static-credential auth on inbound endpoints; invalid tokens get 401.
- Send minimal task context to peers — never the full codebase, never secrets.
- Remote output is advisory until locally validated.

## Repo layout

```
scripts/
  setup-a2a-env.ps1    # generate + persist A2A credentials (User scope)
  start-a2a.ps1        # start opencode serve + opencode-a2a as background jobs
  stop-a2a.ps1         # stop them (idempotent)
  test-a2a-smoke.ps1   # 7-check end-to-end smoke test
docs/
  A2A.md               # full reference + troubleshooting
```

## License

MIT for the scripts/docs in this repo. `opencode-a2a` itself is Apache-2.0
(© Intelligent-Internet).
