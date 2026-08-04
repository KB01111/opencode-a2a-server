# start-a2a.ps1 — start opencode serve (4096) + opencode-a2a sidecar (8000) as background jobs.
# Writes job info to scripts\a2a.pid.json.
#
# NOTE (verified): do NOT set OPENCODE_SERVER_PASSWORD for this local loopback
# setup — opencode-a2a's upstream client cannot authenticate to a
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

# Read User-scope credentials into this process so child jobs inherit them.
$cred = [Environment]::GetEnvironmentVariable('A2A_STATIC_AUTH_CREDENTIALS', 'User')
if (-not $cred) {
    Write-Warning 'A2A_STATIC_AUTH_CREDENTIALS not set at User scope. Run scripts\setup-a2a-env.ps1 first.'
} else {
    $env:A2A_STATIC_AUTH_CREDENTIALS = $cred
    Write-Output 'A2A_STATIC_AUTH_CREDENTIALS: set (value not shown)'
}
$env:PYTHONIOENCODING = 'utf-8'

$pids = [ordered]@{ opencodeServe = $null; a2aSidecar = $null; startedAt = (Get-Date -Format 'o') }

if (Test-PortListening 4096) {
    Write-Output 'opencode serve: port 4096 already listening - not starting a duplicate.'
} else {
    # Deliberately clear OPENCODE_SERVER_PASSWORD so the loopback server is open to the sidecar.
    $job = Start-Job -Name 'opencode-serve' -ScriptBlock {
        $env:OPENCODE_SERVER_PASSWORD = ''
        & opencode serve --hostname 127.0.0.1 --port 4096 2>&1
    }
    $pids.opencodeServe = $job.Id
    Write-Output "opencode serve: started as background job $($job.Id) on 127.0.0.1:4096"
    Start-Sleep -Seconds 4
}

if (Test-PortListening 8000) {
    Write-Output 'opencode-a2a: port 8000 already listening - not starting a duplicate.'
} else {
    $job = Start-Job -Name 'opencode-a2a' -ScriptBlock {
        param($c)
        $env:A2A_STATIC_AUTH_CREDENTIALS = $c
        $env:PYTHONIOENCODING = 'utf-8'
        & opencode-a2a serve 2>&1
    } -ArgumentList $cred
    $pids.a2aSidecar = $job.Id
    Write-Output "opencode-a2a: started as background job $($job.Id) on 127.0.0.1:8000"
}

$pids | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding utf8
Write-Output "PID file written: $pidFile"
Write-Output 'Verify Agent Card: curl http://127.0.0.1:8000/.well-known/agent-card.json'
