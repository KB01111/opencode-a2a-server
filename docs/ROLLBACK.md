# Rollback

Backup location: `C:\Users\kevin\.config\opencode\.opencode-backups\20260803-032236\`
Contains: `manifest.json` (SHA-256 checksums), `rollback.ps1`, `files\` (backed-up files).

## How to run

```powershell
powershell -File "C:\Users\kevin\.config\opencode\.opencode-backups\20260803-032236\rollback.ps1"
# or the thin wrapper:
powershell -File "C:\Users\kevin\.config\opencode\scripts\rollback.ps1"
```

The script is idempotent: files already matching the backup are reported UNCHANGED.

## What it restores

- `opencode.json` — verified against manifest SHA-256 before overwrite
- `AGENTS.md` — same verification
- `package.json` — same verification

And removes the directories created by the multi-agent setup:

- `agents\`
- `rules\`
- `docs\`
- `scripts\`

## What it does NOT remove

- npm plugin cache in `~/.cache/opencode` — harmless; plugins simply won't be loaded
  once removed from the plugin array. Reinstall with `opencode plugin <name> -g` if
  you roll forward again.
- `dcp.jsonc` — the dcp plugin's own config. Delete it manually if you want a fully
  clean state:
  ```powershell
  Remove-Item -LiteralPath "C:\Users\kevin\.config\opencode\dcp.jsonc"
  ```
- `tui.json` changes (rules sidebar + dcp entries) — edit manually if desired.
- The backup directory itself.

## After rollback

Restart OpenCode Desktop (fully quit, including tray) so it reloads config and
unloads plugins.
