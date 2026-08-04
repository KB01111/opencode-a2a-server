# stop-a2a.ps1 — stop jobs started by start-a2a.ps1. Idempotent.
$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir 'a2a.pid.json'

if (-not (Test-Path -LiteralPath $pidFile)) {
    Write-Output 'No a2a.pid.json found — nothing to stop.'
    exit 0
}

$pids = Get-Content -Raw -LiteralPath $pidFile | ConvertFrom-Json
foreach ($name in 'opencode-serve', 'opencode-a2a') {
    $job = Get-Job -Name $name -ErrorAction SilentlyContinue
    if ($job) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        Write-Output "Stopped job: $name"
    } else {
        Write-Output "Job not running: $name"
    }
}

Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
Write-Output 'PID file removed.'
exit 0
