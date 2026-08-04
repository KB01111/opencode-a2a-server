# OpenCode Desktop

OpenCode Desktop reads the SAME global config as the CLI:
`C:\Users\kevin\.config\opencode\opencode.json` (plus agents/, rules/, plugins).

## Restart policy

Restart Desktop after any of these changes:

- opencode.json edits (agents, plugins, default_agent, watcher, providers)
- plugin install/update/remove (`opencode plugin <name> -g`)
- environment variable changes (EXA_API_KEY, A2A_*, etc.)
- agent definition changes in agents/*.md
- rules changes in rules/*.mdc

## Environment variable gotcha (Windows)

Windows GUI apps do NOT inherit env vars set in an already-open shell. `setx` or
`$env:FOO=...` in a PowerShell window will not reach a running Desktop process.

Correct procedure:

```powershell
[Environment]::SetEnvironmentVariable('EXA_API_KEY', '<value>', 'User')
```

Then fully quit OpenCode Desktop (tray icon too) and start it again.

## How to verify the setup in Desktop

1. Open a project.
2. Confirm the default agent is `orchestrator` (agent selector, or `default_agent`
   in opencode.json).
3. @-mention a specialist (e.g. `@explorer`, `@reviewer`) — they should appear in
   autocomplete.
4. Run `/status` to see loaded plugins (forking-agents, ast-lsp, scout, dcp,
   adversarial-review, rules; auto-resume may fail to load — known issue).
5. Run `scripts\validate.ps1` for a CLI-side check.

## TUI

`tui.json` loads the opencode-rules TUI sidebar and dcp. Rules from
`~/.config/opencode/rules` (this directory) and per-project `.opencode/rules` both apply.
