# Subagents (forking-agents plugin)

Plugin: `opencode-forking-agents-plugin`, installed globally via
`opencode plugin opencode-forking-agents-plugin -g`.

Companion plugin: `opencode-subagent-threads` (local, `./plugins/opencode-subagent-threads`)
renders subagent child sessions as compact inline blocks in the parent session
sidebar, so subagent work stays visible inline instead of opening separate
top-level conversation windows. Exposes a `subagent_threads` tool to query
child session status programmatically.

## Config (opencode.json plugin array)

- `fork.default: true` — subagents run as forks of the current session.
- `fork.reviewDefault: false`
- `background.timeoutMs: 900000` (15 min cap per background task)
- `background.allowWriteCapable: false` — write-capable agents cannot run in background.
- `model.agents` — per-agent model map (explorer/implementer/tester on
  deepseek-v4-flash-free; reviewer/web-researcher/security-reviewer on kimi-k3).

## Tools

- `subagents_run` — synchronous run; blocks until the subagent finishes.
- `subagents_delegate` — background run; returns a task id immediately.
- `subagents_read` — read a background task's current output/status.
- `subagents_list` — list running/finished tasks.
- `subagents_cancel` — cancel a background task.
- `subagents_models` — inspect the per-agent model map.
- `subagent_threads` — list child sessions with status and latest output preview (from `opencode-subagent-threads`).

## Sync vs background policy

- Synchronous: implementer, tester, reviewer (their output gates the next lifecycle step).
- Background allowed: explorer, web-researcher (read-only research/exploration).
- Background denied: any write-capable agent (allowWriteCapable=false).

## Delegation envelope (required fields for every delegation)

1. **Objective** — single, bounded goal.
2. **Scope** — files/dirs the agent may touch.
3. **Exclusions** — what is explicitly out of scope.
4. **Evidence** — what proof to return (file:line, commands + exit codes, URLs).
5. **Required tools** — tools the agent is expected to use.
6. **Acceptance criteria** — how the orchestrator judges completion.
7. **Output contract** — exact shape of the final report.

## Concurrency limits

- explorer: max 2 in parallel
- web-researcher: max 1
- implementer: max 1
- tester + reviewer combined: max 1

Never delegate the same objective to two write-capable agents.
