# test-a2a-smoke.ps1 — 7-check end-to-end A2A smoke test against a running local pair.
# Prereq: scripts\start-a2a.ps1 has been run (opencode serve on 4096 + sidecar on 8000).
$ErrorActionPreference = 'Continue'
$base = 'http://127.0.0.1:8000'
$token = [Environment]::GetEnvironmentVariable('A2A_CLIENT_BEARER_TOKEN', 'User')
if (-not $token) { Write-Error 'A2A_CLIENT_BEARER_TOKEN not set (User scope). Run setup-a2a-env.ps1.'; exit 1 }

$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$sendBody = @{ message = @{ role = 'ROLE_USER'; parts = @(@{ text = 'Reply with exactly: A2A_OK' }) } } | ConvertTo-Json -Depth 6
$pass = 0; $total = 7

# 1. Agent Card discovery (public)
try { $card = Invoke-RestMethod -Uri "$base/.well-known/agent-card.json" -TimeoutSec 8; Write-Output "1 CARD: PASS name=$($card.name) skills=$($card.skills.Count)"; $pass++ } catch { Write-Output "1 CARD: FAIL $($_.Exception.Message)" }

# 2. Invalid auth rejected
try { Invoke-RestMethod -Uri "$base/v1/message:send" -Method Post -Headers @{ Authorization = 'Bearer wrong'; 'Content-Type' = 'application/json' } -Body $sendBody -TimeoutSec 10 | Out-Null; Write-Output '2 INVALID-AUTH: FAIL (accepted)' } catch { Write-Output "2 INVALID-AUTH: PASS rejected $($_.Exception.Response.StatusCode.value__)"; $pass++ }

# 3. Authenticated send
$task = $null
try {
    $task = ((Invoke-WebRequest -Uri "$base/v1/message:send" -Method Post -Headers $headers -Body $sendBody -TimeoutSec 300 -UseBasicParsing).Content | ConvertFrom-Json).task
    if ($task.status.state -eq 'TASK_STATE_COMPLETED') { Write-Output "3 SEND: PASS state=$($task.status.state)"; $pass++ } else { Write-Output "3 SEND: FAIL state=$($task.status.state)" }
} catch { Write-Output "3 SEND: FAIL $(if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $_.Exception.Message })" }

# 4. SSE streaming
try {
    $req = [System.Net.HttpWebRequest]::Create("$base/v1/message:stream"); $req.Method = 'POST'
    $req.Headers.Add('Authorization', "Bearer $token"); $req.ContentType = 'application/json'; $req.Timeout = 300000
    $bytes = [Text.Encoding]::UTF8.GetBytes($sendBody); $req.ContentLength = $bytes.Length
    $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()
    $rsp = $req.GetResponse(); $sr = New-Object IO.StreamReader($rsp.GetResponseStream())
    $all = ''; while (($l = $sr.ReadLine()) -ne $null) { $all += $l; if ($all -match 'TASK_STATE_COMPLETED|TASK_STATE_FAILED') { break } }
    if ($all -match 'TASK_STATE_COMPLETED') { Write-Output '4 STREAM: PASS completed event'; $pass++ } else { Write-Output '4 STREAM: FAIL no completion' }
    $sr.Close(); $rsp.Close()
} catch { Write-Output "4 STREAM: FAIL $($_.Exception.Message)" }

# 5. Task retrieval (JSON-RPC GetTask)
if ($task -and $task.id) {
    try {
        $rpc = @{ jsonrpc = '2.0'; id = 1; method = 'GetTask'; params = @{ id = $task.id } } | ConvertTo-Json -Depth 5
        $r2 = (Invoke-WebRequest -Uri "$base/" -Method Post -Headers $headers -Body $rpc -TimeoutSec 30 -UseBasicParsing).Content | ConvertFrom-Json
        if ($r2.result.status.state) { Write-Output "5 TASK-GET: PASS state=$($r2.result.status.state)"; $pass++ } else { Write-Output '5 TASK-GET: FAIL empty state' }
    } catch { Write-Output "5 TASK-GET: FAIL $($_.Exception.Message)" }
} else { Write-Output '5 TASK-GET: SKIP (no task id)' }

# 6. Session continuity via contextId
if ($task -and $task.contextId) {
    try {
        $b2 = @{ message = @{ role = 'ROLE_USER'; parts = @(@{ text = 'What exact string did I ask for earlier? Reply with just it.' }); contextId = $task.contextId } } | ConvertTo-Json -Depth 6
        $j2 = ((Invoke-WebRequest -Uri "$base/v1/message:send" -Method Post -Headers $headers -Body $b2 -TimeoutSec 300 -UseBasicParsing).Content | ConvertFrom-Json).task
        if ($j2.status.state -eq 'TASK_STATE_COMPLETED') { Write-Output "6 CONTINUITY: PASS state=$($j2.status.state)"; $pass++ } else { Write-Output "6 CONTINUITY: FAIL state=$($j2.status.state)" }
    } catch { Write-Output "6 CONTINUITY: FAIL $($_.Exception.Message)" }
} else { Write-Output '6 CONTINUITY: SKIP (no context id)' }

# 7. Cancellation
try {
    $b3 = @{ message = @{ role = 'ROLE_USER'; parts = @(@{ text = 'Count from 1 to 999999, one number per message' }) } } | ConvertTo-Json -Depth 6
    $req3 = [System.Net.HttpWebRequest]::Create("$base/v1/message:stream"); $req3.Method = 'POST'
    $req3.Headers.Add('Authorization', "Bearer $token"); $req3.ContentType = 'application/json'; $req3.Timeout = 60000
    $by3 = [Text.Encoding]::UTF8.GetBytes($b3); $req3.ContentLength = $by3.Length
    $st3 = $req3.GetRequestStream(); $st3.Write($by3, 0, $by3.Length); $st3.Close()
    $rsp3 = $req3.GetResponse(); $sr3 = New-Object IO.StreamReader($rsp3.GetResponseStream())
    $l1 = $sr3.ReadLine(); $taskId = $null
    if ($l1 -match '"taskId"\s*:\s*"([^"]+)"') { $taskId = $Matches[1] }
    if ($taskId) {
        $rc = @{ jsonrpc = '2.0'; id = 2; method = 'CancelTask'; params = @{ id = $taskId } } | ConvertTo-Json -Depth 5
        $rcr = (Invoke-WebRequest -Uri "$base/" -Method Post -Headers $headers -Body $rc -TimeoutSec 30 -UseBasicParsing).Content | ConvertFrom-Json
        if ($rcr.result.status.state -match 'CANCEL') { Write-Output "7 CANCEL: PASS state=$($rcr.result.status.state)"; $pass++ } else { Write-Output "7 CANCEL: FAIL state=$($rcr.result.status.state)" }
    } else { Write-Output '7 CANCEL: SKIP (no task id from stream)' }
    $sr3.Close(); $rsp3.Close()
} catch { Write-Output "7 CANCEL: FAIL $($_.Exception.Message)" }

Write-Output "A2A SMOKE: $pass/$total PASS"
if ($pass -eq $total) { exit 0 } else { exit 1 }
