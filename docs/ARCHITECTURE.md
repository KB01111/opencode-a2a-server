# Architecture

Multi-agent OpenCode setup on Windows 11 (OpenCode 1.18.4, PowerShell, bun 1.3.14, node 24.15.0).

## Agent tree

```
orchestrator (primary, merge/moonshot/kimi-k3, reasoningEffort high)
├── explorer          (subagent, opencode/deepseek-v4-flash-free, read-only)
├── web-researcher    (subagent, merge/moonshot/kimi-k3, read-only)
├── implementer       (subagent, opencode/deepseek-v4-flash-free, write-capable)
├── tester            (subagent, opencode/deepseek-v4-flash-free, bash ask)
├── reviewer          (subagent, merge/moonshot/kimi-k3, read-only)
├── security-reviewer (subagent, merge/moonshot/kimi-k3, read-only)
├── a2a-coordinator   (subagent, merge/moonshot/kimi-k3, no local tools)
└── A2A peers         (remote / isolated agents, advisory only)
```

## Communication layers

- **Local subagents** — run in-runtime via the opencode-forking-agents-plugin
  (`fork.default=true`). Use these for all in-repo work: explore, implement, test, review.
  Child sessions are rendered as compact inline threads in the parent session
  sidebar by the `opencode-subagent-threads` plugin (local, `./plugins/opencode-subagent-threads`),
  keeping subagent activity bound to the parent thread instead of opening
  separate top-level windows.
- **A2A** — the opencode-a2a Python sidecar on top of `opencode serve`. Use ONLY for
  remote or isolated agents that live outside this runtime. See A2A.md.
- **MCP (context7)** — external documentation/data provider. NOT an agent-to-agent
  channel; never route delegation through MCP.

## Task lifecycle

```
DISCOVER -> PLAN -> ASSIGN -> IMPLEMENT -> DIAGNOSE -> TEST -> REVIEW -> REPAIR -> VERIFY -> COMPLETE
```

- DISCOVER: explorer / web-researcher gather evidence (file:line, cited URLs).
- PLAN + ASSIGN: orchestrator decomposes; parallel tasks get non-overlapping write scopes.
- IMPLEMENT + DIAGNOSE: implementer edits, runs lsp_diagnostics.
- TEST: tester runs targeted tests, reports commands + exit codes.
- REVIEW: reviewer (and security-reviewer for sensitive work) returns a verdict.
- REPAIR loops back to IMPLEMENT on CONDITIONAL_PASS / FAIL.
- VERIFY + COMPLETE: orchestrator checks acceptance criteria against evidence and owns
  final acceptance. Subagent claims alone are not completion evidence.
