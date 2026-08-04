# setup-a2a-env.ps1 — generate and persist A2A credentials at User scope.
# Idempotent: reuses existing credentials if already set. Never prints secret values.
$ErrorActionPreference = 'Stop'

function New-HexToken([int]$Bytes = 24) {
    -join (1..($Bytes * 2) | ForEach-Object { '0123456789abcdef'[(Get-Random -Max 16)] })
}

$existingCred = [Environment]::GetEnvironmentVariable('A2A_STATIC_AUTH_CREDENTIALS', 'User')
$existingTok = [Environment]::GetEnvironmentVariable('A2A_CLIENT_BEARER_TOKEN', 'User')

if ($existingCred -and $existingTok) {
    Write-Output 'A2A credentials already set at User scope - keeping them. Delete the variables to regenerate.'
    exit 0
}

$token = New-HexToken 24
$cred = (@{ scheme = 'bearer'; token = $token; principal = 'local-orchestrator'; capabilities = @('a2a.messages.send') } | ConvertTo-Json -Compress)
[Environment]::SetEnvironmentVariable('A2A_STATIC_AUTH_CREDENTIALS', "[$cred]", 'User')
[Environment]::SetEnvironmentVariable('A2A_CLIENT_BEARER_TOKEN', $token, 'User')
Write-Output "A2A_STATIC_AUTH_CREDENTIALS + A2A_CLIENT_BEARER_TOKEN set at User scope (token length $($token.Length), value not printed)."
Write-Output 'Restart open shells / OpenCode Desktop so they inherit the variables.'
