# A2A (Agent-to-Agent)

`opencode-a2a` is a Python sidecar that exposes an OpenCode runtime as an A2A peer.
Installed with `uv tool install opencode-a2a` (uv 0.11.29, Python 3.14.5).

## Architecture

```
opencode serve (127.0.0.1:4096)
        ↑ OPENCODE_BASE_URL
opencode-a2a serve (127.0.0.1:8000)
  ├── Agent Card: http://127.0.0.1:8000/.well-known/agent-card.json
  └── A2A JSON-RPC endpoints
```

The sidecar talks to the local `opencode serve` HTTP API; remote peers talk to the
sidecar. Loopback-only by default.

## Install / run

```powershell
uv tool install opencode-a2a
opencode serve --port 4096        # terminal 1 (or scripts\start-a2a.ps1)
opencode-a2a serve                # terminal 2
```

`scripts\start-a2a.ps1` starts both as background jobs; `scripts\stop-a2a.ps1` stops them.

## Environment variables

- `A2A_STATIC_AUTH_CREDENTIALS` — JSON map of accepted inbound credentials (server side).
- `A2A_CLIENT_BEARER_TOKEN` — token used by the `a2a_call` tool for outbound calls.
- `A2A_HOST` / `A2A_PORT` — bind address (default 127.0.0.1:8000).
- `OPENCODE_BASE_URL` — where the sidecar finds opencode serve (default http://127.0.0.1:4096).

## Peers

Logical peers: **research-agent, ui-agent, review-agent, devops-agent**. These are
roles, not running services — configure actual peer URLs per deployment. Verify each
peer's Agent Card before delegating (rules/a2a-safety.mdc).

## Security

- Loopback-only binding by default; do not expose beyond 127.0.0.1 without TLS + auth.
- Bearer/static-credential auth on inbound endpoints.
- Send minimal task context — never the full codebase; never forward secrets.
- Remote output is advisory until locally validated by the orchestrator.

## Verified protocol details (smoke-tested 2026-08-03, 7/7 PASS)

- **Do NOT set `OPENCODE_SERVER_PASSWORD`** for the local loopback sidecar setup —
  the sidecar's upstream client cannot authenticate to a password-protected
  `opencode serve`. Security boundary = loopback binding + A2A bearer auth on 8000.
- REST payload: roles must be `ROLE_USER` / `ROLE_AGENT`; parts use direct fields
  (`{"text": "..."}`, no `kind` wrapper).
- JSON-RPC 1.0 methods are PascalCase: `SendMessage`, `SendStreamingMessage`,
  `GetTask`, `ListTasks`, `CancelTask`, `SubscribeToTask`, plus OpenCode extensions
  (`opencode.sessions.*`, `opencode.providers.list`, `opencode.models.list`).
- Task states: `TASK_STATE_COMPLETED`, `TASK_STATE_CANCELED`, etc.
- Verified: Agent Card discovery, 401 rejection of bad bearer token, authenticated
  send, SSE streaming, GetTask, contextId session continuity, CancelTask.
- On Windows PowerShell: set `$env:PYTHONIOENCODING='utf-8'` before running
  `opencode-a2a` (its `--help`/banner crashes on cp1252 consoles otherwise).

## Two-instance local smoke test

1. Start instance A: `opencode serve --port 4096` + `opencode-a2a serve` (port 8000).
2. Start instance B on different ports (e.g. 4097/8001) with its own credentials.
3. From A, fetch B's Agent Card: `curl http://127.0.0.1:8001/.well-known/agent-card.json`.
4. From A, run `a2a_call` against B with `A2A_CLIENT_BEARER_TOKEN`; confirm task
   lifecycle (submitted -> working -> completed) and cancellation handling.
