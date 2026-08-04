# Model Mapping (resolved 2026-08-03 via `opencode models` on this machine)

| Role | OpenCode model ID | Notes |
|---|---|---|
| orchestrator | `merge/moonshot/kimi-k3` | Kimi K3 via merge.dev gateway; primary agent; reasoningEffort: high |
| implementer | `opencode/deepseek-v4-flash-free` | DeepSeek V4 Flash (free tier, OpenCode provider) |
| explorer | `opencode/deepseek-v4-flash-free` | read-only background/synchronous exploration |
| tester | `opencode/deepseek-v4-flash-free` | routine command execution |
| reviewer | `merge/moonshot/kimi-k3` | independent review, high reasoning |
| security-reviewer | `merge/moonshot/kimi-k3` | security-sensitive reviews only |
| web-researcher | `merge/moonshot/kimi-k3` | cited research |
| a2a-coordinator | `merge/moonshot/kimi-k3` | remote peer delegation |

## Alternates discovered (not assigned)
- `tokenrouter/moonshotai/kimi-k3-free` — free Kimi K3 via TokenRouter gateway (backup for orchestrator/reviewer roles if merge.dev fails)
- `opencode-go/deepseek-v4-flash` — paid DeepSeek V4 Flash via opencode-go (upgrade path if free tier is rate-limited)
- `opencode-go/kimi-k3` — Kimi K3 via opencode-go

## Intended mapping (target state per plan)
- Kimi: `kimi-k3` official API name; resolved here as `merge/moonshot/kimi-k3`
- DeepSeek: `deepseek-v4-flash` official API name; resolved here as `opencode/deepseek-v4-flash-free`

## Missing providers (reported, not silently substituted)
- No direct Moonshot AI provider configured (KIMI_API_KEY/MOONSHOT_API_KEY not set)
- No direct DeepSeek provider configured (DEEPSEEK_API_KEY not set)
- Fallbacks above use already-authenticated gateways (merge.dev, OpenCode built-in).
