# test-subagents.ps1 — smoke checklist for the forking-agents plugin.
# Automated part: verify plugin is configured. Interactive TUI/Desktop steps are
# printed as a manual checklist (they cannot be fully automated).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$cfg = Get-Content -Raw -LiteralPath (Join-Path $root 'opencode.json') | ConvertFrom-Json

$configured = $false
foreach ($p in $cfg.plugin) {
    if (($p -is [string] -and $p -eq 'opencode-forking-agents-plugin') -or
        ($p -isnot [string] -and $p[0] -eq 'opencode-forking-agents-plugin')) {
        $configured = $true
    }
}

if (-not $configured) {
    Write-Output 'FAIL: opencode-forking-agents-plugin is NOT in the plugin array.'
    exit 1
}
Write-Output 'OK: opencode-forking-agents-plugin is in the plugin array.'
Write-Output ''
Write-Output 'Manual smoke checklist (run in OpenCode TUI or Desktop):'
Write-Output ' [ ] 1. Explorer synchronous: ask orchestrator to "use subagents_run with explorer to map the entry point of this project" - expect file:line evidence.'
Write-Output ' [ ] 2. Background exploration: "delegate background exploration of module X to explorer" - expect a task id back immediately.'
Write-Output ' [ ] 3. subagents_read: read the background task output mid-run.'
Write-Output ' [ ] 4. subagents_list: confirm running/finished tasks appear.'
Write-Output ' [ ] 5. subagents_cancel: cancel a background explorer task; confirm it stops.'
Write-Output ' [ ] 6. Nested depth-2: have the orchestrator delegate to an agent that itself delegates one level deeper (subagent_depth=2); confirm a third level is rejected.'
Write-Output ' [ ] 7. Write-capable background rejection: "delegate implementer in background" - expect refusal (background.allowWriteCapable=false).'
Write-Output ''
Write-Output 'Plugin configured: yes. Interactive steps above must be verified by hand.'
exit 0
