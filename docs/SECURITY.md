# Security

## Secrets policy

- No secrets in tracked files. Credentials belong in User-scope environment variables.
- **Flagged:** a pre-existing `CONTEXT7_API_KEY` is stored in plaintext in
  `opencode.json` (mcp.headers). It predates this setup; rotate it and move to an
  env-based header if the provider supports it.
- A2A credentials live only in env vars: `A2A_STATIC_AUTH_CREDENTIALS`,
  `A2A_CLIENT_BEARER_TOKEN`. Never commit them, never forward them to peers.
- Scripts in `scripts/` never print secret values (presence checks only).

## Agent permission model

- explorer / reviewer: read-only; bash denied except read-only git (status/diff/log).
- tester: bash default `ask` — every command needs approval.
- implementer: edit/write allowed; bash default `ask`; destructive git forbidden by rule.
- Write-capable background execution disabled globally
  (`background.allowWriteCapable=false`).
- a2a-coordinator: no local edit/write/bash at all; only `a2a_call`.
- share=manual: sessions are not shared/uploaded automatically.

## A2A exposure

- Loopback-only binding (127.0.0.1) by default for both `opencode serve` (4096) and
  the sidecar (8000).
- Static-credential / bearer auth on inbound A2A endpoints.
- Minimal task context to peers; remote output advisory until locally validated.

## Filesystem / network exposure

- watcher ignore list configured (node_modules, dist, build, .git, .cache, coverage,
  target) to limit file-watch surface.
- clone_repo writes only into `~/.cache/opencode/repos`.
- dcp.jsonc protectedTools prevent pruning of subagent/A2A/diagnostics evidence.

## Rollback

Full pre-setup state is backed up with SHA-256 checksums:
`.opencode-backups\20260803-032236\` (see ROLLBACK.md).
