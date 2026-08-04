# Web Search (opencode-scout)

Plugin: `opencode-scout`, installed globally. Provides `web_search` and `clone_repo`.

## Provider fallback chain

`web_search` tries providers in order:

1. **Exa** — via `EXA_API_KEY`
2. **TinyFish** — via `TINYFISH_API_KEY`
3. **Gemini** — via `GEMINI_API_KEY`

First configured provider wins. With no keys set, `web_search` is INACTIVE
(reports "no providers configured").

## Current state

No API keys are currently set. `clone_repo` works WITHOUT any keys; `web_search`
does not.

## Enabling web_search

Set a User-scope environment variable, then restart OpenCode Desktop (GUI apps do not
inherit env vars from an already-open shell):

```powershell
[Environment]::SetEnvironmentVariable('EXA_API_KEY', '<your-key>', 'User')
# or TINYFISH_API_KEY / GEMINI_API_KEY
```

Then fully quit and restart OpenCode Desktop. Verify by asking the web-researcher to
run a search.

## clone_repo

- Clones external repositories read-only into `~/.cache/opencode/repos`.
- Safe: cache-only, never modifies the original repo or your project.
- Used by web-researcher for external repository analysis.
- Works without any API keys.

## Rules

- Prefer official docs over blogs; cite URLs (rules/web-research.mdc).
- For library/framework docs, use the context7 MCP server first when available.
