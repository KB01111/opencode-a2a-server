# setup.ps1 — idempotent re-setup of global plugins, then validation.
# Note: config (opencode.json), agents (agents/*.md), rules (rules/*.mdc), and docs
# are file-based and already in place — they need no reinstall. This script only
# ensures the global plugins are installed and the setup validates.
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$plugins = @(
    'opencode-forking-agents-plugin',
    'opencode-plugin-ast-lsp',
    'opencode-scout',
    '@tarquinen/opencode-dcp',
    'opencode-auto-resume',
    '@capybearista/opencode-adversarial-review',
    'opencode-rules'
)

foreach ($p in $plugins) {
    Write-Output "Installing plugin (global): $p"
    & opencode plugin $p -g
    if ($LASTEXITCODE -ne 0) { Write-Warning "plugin install returned exit code $LASTEXITCODE for $p" }
}

Write-Output ''
Write-Output 'Running validate.ps1 ...'
& powershell -NoProfile -File (Join-Path $scriptDir 'validate.ps1')
exit $LASTEXITCODE
