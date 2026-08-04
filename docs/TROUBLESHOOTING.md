# Troubleshooting

## auto-resume fails to load

Symptom: plugin load error `todos.filter is not a function` on OpenCode 1.18.4.
Impact: harmless — `opencode-auto-resume` stays in the plugin array but is effectively
disabled; everything else works. Fix is pending upstream.
If the log noise is a problem, remove `"opencode-auto-resume"` from the `plugin` array
in opencode.json and restart.

## web_search: "no providers configured"

No EXA_API_KEY / TINYFISH_API_KEY / GEMINI_API_KEY set. Set one at User scope and
restart Desktop (see WEB-SEARCH.md). `clone_repo` works without keys.

## Plugin reinstall / repair

```powershell
opencode plugin <name> -g --force
```

Run for any plugin that misbehaves after an OpenCode upgrade.

## Inspecting logs

```powershell
opencode --print-logs
```

Use to diagnose plugin load failures and tool errors.

## ast-lsp first use

The first lsp_* call may be slow: the plugin auto-installs the language server.
Requires `bun` on PATH (`bun --version` should print 1.3.14). Windows-specific
behavior should be verified on first real LSP use; if a server fails to start, retry
after confirming bun.

## orchestrator is not the default agent

Check `default_agent: "orchestrator"` in opencode.json and `mode: primary` in
`agents\orchestrator.md`. Restart Desktop after fixing.

## Full rollback

See ROLLBACK.md — restores opencode.json / AGENTS.md / package.json from the
SHA-256-verified backup and removes agents/, rules/, docs/, scripts/.

## Unused provider

The `tokenrouter` provider in opencode.json is an unused backup; safe to ignore.
