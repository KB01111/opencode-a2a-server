# test-model-routing.ps1 — show which model each agent is routed to.
# Pure file parsing of opencode.json + agents/*.md frontmatter. No API calls, no secrets.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$cfg = Get-Content -Raw -LiteralPath (Join-Path $root 'opencode.json') | ConvertFrom-Json

Write-Output "default_agent : $($cfg.default_agent)"
Write-Output "subagent_depth: $($cfg.subagent_depth)"
Write-Output ''
Write-Output 'Per-agent model assignments (from agents/*.md frontmatter):'
Write-Output ('{0,-20} {1}' -f 'agent', 'model')
Write-Output ('{0,-20} {1}' -f '-----', '-----')

Get-ChildItem -LiteralPath (Join-Path $root 'agents') -Filter '*.md' -File |
    Sort-Object Name |
    ForEach-Object {
        $model = '(none)'
        foreach ($line in (Get-Content -LiteralPath $_.FullName)) {
            if ($line -match '^model: (.+)$') { $model = $Matches[1].Trim(); break }
        }
        Write-Output ('{0,-20} {1}' -f $_.BaseName, $model)
    }

Write-Output ''
Write-Output 'Forking-agents plugin per-agent model map (opencode.json):'
foreach ($p in $cfg.plugin) {
    if ($p -isnot [string] -and $p[0] -eq 'opencode-forking-agents-plugin') {
        $map = $p[1].model.agents
        if ($map) {
            foreach ($prop in $map.PSObject.Properties) {
                Write-Output ('  {0,-20} {1}' -f $prop.Name, $prop.Value)
            }
        } else {
            Write-Output '  (no model map configured)'
        }
    }
}
exit 0
