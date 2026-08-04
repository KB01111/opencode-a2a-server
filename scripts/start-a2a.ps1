# start-a2a.ps1 — start opencode serve (4096) + opencode-a2a sidecar (8000) as background jobs.
# Writes PIDs to scripts\a2a.pid.json. Warns (without printing value) if
# A2A_STATIC_AUTH_CREDENTIALS is not set.
# NOTE (verified 2026-08-03): do NOT set OPENCODE_SERVER_PASSWORD for this local
# loopback setup — opencode-a2a's upstream client cannot authenticate to a
# password-protected opencode serve. Loopback binding + A2A bearer auth is the
# security boundary. A2A 1.0 JSON-RPC methods are PascalCase (GetTask/CancelTask)
# and REST roles are ROLE_USER/ROLE_AGENT.
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir 'a2a.pid.json'

function Test-PortListening([int]$Port) {
    $c = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    return ($null -ne $c)
}

if (-not $env:A2A_STATIC_AUTH_CREDENTIALS) {
    Write-Warning 'A2A_STATIC_AUTH_CREDENTIALS is not set. Inbound A2A endpoints may accept unauthenticated requests depending on sidecar config. Set it at User scope and restart this shell.'
} else {
    Write-Output 'A2A_STATIC_AUTH_CREDENTIALS: set (value not shown)'
}

$pids = [ordered]@{ opencodeServe = $null; a2aSidecar = $null; startedAt = (Get-Date -Format 'o') }

if (Test-PortListening 4096) {
    Write-Output 'opencode serve: port 4096 already listening — not starting a duplicate.'
} else {
    $job = Start-Job -Name 'opencode-serve' -ScriptBlock { & opencode serve --port 4096 2>&1 }
    $pids.opencodeServe = $job.Id
    Write-Output "opencode serve: started as background job $($job.Id) on 127.0.0.1:4096"
    Start-Sleep -Seconds 3
}

if (Test-PortListening 8000) {
    Write-Output 'opencode-a2a: port 8000 already listening — not starting a duplicate.'
} else {
    $job = Start-Job -Name 'opencode-a2a' -ScriptBlock { & opencode-a2a serve 2>&1 }
    $pids.a2aSidecar = $job.Id
    Write-Output "opencode-a2a: started as background job $($job.Id) on 127.0.0.1:8000"
}

$pids | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding utf8
Write-Output "PID file written: $pidFile"
Write-Output 'Verify Agent Card: curl http://127.0.0.1:8000/.well-known/agent-card.json'
