# validate.ps1 — sanity-check the OpenCode multi-agent setup.
# Prints versions, config parse status, agents, plugins, dcp.jsonc, rules count.
# Exit 0 if all present, 1 otherwise. Never prints secret values.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$fail = $false

Write-Output '=== OpenCode version ==='
try {
    $v = (& opencode --version 2>&1 | Select-Object -First 1)
    Write-Output "opencode $v"
} catch {
    Write-Output 'ERROR: opencode not on PATH'
    $fail = $true
}

Write-Output ''
Write-Output '=== Config parse check ==='
$cfgPath = Join-Path $root 'opencode.json'
$cfg = $null
if (Test-Path -LiteralPath $cfgPath) {
    try {
        $cfg = Get-Content -Raw -LiteralPath $cfgPath | ConvertFrom-Json
        Write-Output "opencode.json: parsed OK"
    } catch {
        Write-Output "opencode.json: ConvertFrom-Json failed ($($_.Exception.Message))"
        Write-Output '  note: if file contains comments/trailing commas (jsonc), strict parse failure is expected'
        $fail = $true
    }
} else {
    Write-Output "MISSING: $cfgPath"
    $fail = $true
}

Write-Output ''
Write-Output '=== Agents (agents/*.md) ==='
$agentsDir = Join-Path $root 'agents'
$agentFiles = @()
if (Test-Path -LiteralPath $agentsDir) {
    $agentFiles = @(Get-ChildItem -LiteralPath $agentsDir -Filter '*.md' -File)
    foreach ($a in $agentFiles) {
        $desc = ''
        foreach ($line in (Get-Content -LiteralPath $a.FullName)) {
            if ($line -match '^description:\s*(.+)$') { $desc = $Matches[1]; break }
        }
        Write-Output ("  {0}  --  {1}" -f $a.Name, $desc)
    }
    Write-Output ("  ({0} agent files)" -f $agentFiles.Count)
    if ($agentFiles.Count -lt 8) { Write-Output '  WARNING: fewer than 8 agents'; $fail = $true }
} else {
    Write-Output 'MISSING: agents directory'
    $fail = $true
}

Write-Output ''
Write-Output '=== Plugin array entries ==='
if ($null -ne $cfg -and $cfg.plugin) {
    foreach ($p in $cfg.plugin) {
        if ($p -is [string]) { Write-Output "  $p" }
        else { Write-Output "  $($p[0]) (with options)" }
    }
} else {
    Write-Output 'MISSING: plugin array in opencode.json'
    $fail = $true
}

Write-Output ''
Write-Output '=== dcp.jsonc ==='
$dcpPath = Join-Path $root 'dcp.jsonc'
if (Test-Path -LiteralPath $dcpPath) { Write-Output 'dcp.jsonc: present' }
else { Write-Output 'MISSING: dcp.jsonc'; $fail = $true }

Write-Output ''
Write-Output '=== Rules ==='
$rulesDir = Join-Path $root 'rules'
if (Test-Path -LiteralPath $rulesDir) {
    $rules = @(Get-ChildItem -LiteralPath $rulesDir -Filter '*.mdc' -File)
    Write-Output ("rules/: {0} .mdc files ({1})" -f $rules.Count, (($rules | ForEach-Object Name) -join ', '))
    if ($rules.Count -eq 0) { Write-Output 'WARNING: no .mdc rules found'; $fail = $true }
} else {
    Write-Output 'MISSING: rules directory'
    $fail = $true
}

Write-Output ''
if ($fail) { Write-Output 'VALIDATION: FAIL'; exit 1 } else { Write-Output 'VALIDATION: PASS'; exit 0 }
