# rollback.ps1 — thin wrapper around the backup rollback script.
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir '..\.opencode-backups\20260803-032236\rollback.ps1'
if (-not (Test-Path -LiteralPath $target)) {
    Write-Error "Backup rollback script not found: $target"
    exit 1
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $target
exit $LASTEXITCODE
