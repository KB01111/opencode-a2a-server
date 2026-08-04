# stop-a2a.ps1 — stop the background jobs started by start-a2a.ps1. Idempotent.
$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir 'a2a.pid.json'

foreach ($name in @('opencode-serve', 'opencode-a2a')) {
    $job = Get-Job -Name $name -ErrorAction SilentlyContinue
    if ($job) {
        Stop-Job $name -ErrorAction SilentlyContinue
        Remove-Job $name -Force -ErrorAction SilentlyContinue
        Write-Output "stopped job: $name"
    } else {
        Write-Output "no job named $name (already stopped or different session)"
    }
}

if (Test-Path -LiteralPath $pidFile) {
    Remove-Item -LiteralPath $pidFile -Force
    Write-Output "removed $pidFile"
}
Write-Output 'stop-a2a complete.'
