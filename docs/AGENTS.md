# Agents

Definitions live in `C:\Users\kevin\.config\opencode\agents\*.md`.
Default agent: `orchestrator` (`default_agent` in opencode.json). Max nesting: `subagent_depth=2`.

| Name | Mode | Model | Permissions (summary) | When to use |
|---|---|---|---|---|
| orchestrator | primary | merge/moonshot/kimi-k3 (reasoningEffort: high) | full access; owns decomposition + final acceptance | default entry point for every task |
| implementer | subagent | opencode/deepseek-v4-flash-free | edit/write allow; bash default ask; git status/diff/log allow | focused source edits, refactors, diagnostics repair |
| explorer | subagent | opencode/deepseek-v4-flash-free | read-only (edit/write deny); bash deny except git log/diff/status | symbol discovery, dependency analysis, call paths, test location |
| tester | subagent | opencode/deepseek-v4-flash-free | edit/write deny; bash default ask | run tests, lint, type checks, builds; report exit codes |
| reviewer | subagent | merge/moonshot/kimi-k3 (reasoningEffort: high) | read-only; bash deny except git diff/log/status | independent review with PASS/CONDITIONAL_PASS/FAIL verdict |
| security-reviewer | subagent | merge/moonshot/kimi-k3 (reasoningEffort: high) | read-only; bash deny | security-sensitive work: auth, tokens, injection, secrets |
| web-researcher | subagent | merge/moonshot/kimi-k3 | read-only; bash deny | cited external research, official docs, external repos |
| a2a-coordinator | subagent | merge/moonshot/kimi-k3 | edit/write/bash deny; uses a2a_call | delegate bounded tasks to remote A2A peers |

## Notes

- Implementer/explorer/tester use the free-tier DeepSeek V4 Flash model for cheap bulk
  work; reasoning-heavy roles (review, research, A2A, orchestration) use Kimi K3.
- The forking-agents plugin per-agent model map (in opencode.json) matches the
  `model:` frontmatter in each agent file.
- Write-capable background execution is disabled globally
  (`background.allowWriteCapable=false`); implementer runs synchronously.
