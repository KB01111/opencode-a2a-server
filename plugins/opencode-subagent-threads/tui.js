/**
 * opencode-subagent-threads — TUI plugin
 *
 * Tracks child (subagent) sessions created by the forking-agents plugin
 * and renders a compact status summary in the parent session's sidebar,
 * so subagent work stays visible inline instead of opening separate
 * top-level conversation windows.
 */

import { createSignal, onCleanup } from "solid-js"

/** @param {import("@opencode-ai/plugin/tui").TuiPluginApi} api */
export const tui = async (api) => {
  const { state, event, slots, theme, lifecycle } = api

  // Map: childSessionID → { info, status, preview }
  const [threads, setThreads] = createSignal(new Map())
  // The session currently in view (potential parent)
  const [activeSessionID, setActiveSessionID] = createSignal(null)

  function updateActiveSession() {
    const route = api.route.current
    if (route.name === "session" && route.params?.sessionID) {
      setActiveSessionID(route.params.sessionID)
    }
  }

  function childThreads(parentID) {
    const map = threads()
    const result = []
    for (const [id, t] of map) {
      if (t.info?.parentID === parentID) {
        result.push({ id, ...t })
      }
    }
    result.sort((a, b) => (b.info?.createdAt ?? 0) - (a.info?.createdAt ?? 0))
    return result
  }

  function refreshThread(sessionID) {
    const session = state.session.get(sessionID)
    if (!session?.parentID) return

    const status = state.session.status(sessionID)
    const messages = state.session.messages(sessionID)
    const lastAssistant = [...messages]
      .reverse()
      .find((m) => m.role === "assistant")

    let preview = ""
    if (lastAssistant) {
      const parts = state.part(lastAssistant.id)
      const texts = parts
        .filter((p) => p.type === "text" && typeof p.text === "string")
        .map((p) => p.text)
      if (texts.length) preview = texts[texts.length - 1].slice(0, 150)
    }

    setThreads((prev) => {
      const next = new Map(prev)
      next.set(sessionID, {
        info: session,
        status: status?.type ?? "running",
        preview,
      })
      return next
    })
  }

  // Track route changes
  updateActiveSession()

  const unsubs = [
    event.on("session.created", (e) => {
      const s = e.properties?.info
      if (s?.parentID) {
        refreshThread(e.properties.sessionID)
      }
    }),
    event.on("session.updated", (e) => {
      if (e.properties?.info?.parentID) {
        refreshThread(e.properties.sessionID)
      }
    }),
    event.on("session.idle", (e) => {
      if (e.properties?.sessionID) refreshThread(e.properties.sessionID)
    }),
    event.on("session.status", (e) => {
      if (e.properties?.sessionID) refreshThread(e.properties.sessionID)
    }),
    event.on("message.updated", (e) => {
      if (e.properties?.sessionID && threads().has(e.properties.sessionID)) {
        refreshThread(e.properties.sessionID)
      }
    }),
    event.on("message.part.updated", (e) => {
      if (e.properties?.sessionID && threads().has(e.properties.sessionID)) {
        refreshThread(e.properties.sessionID)
      }
    }),
    event.on("session.deleted", (e) => {
      if (e.properties?.sessionID) {
        setThreads((prev) => {
          const next = new Map(prev)
          next.delete(e.properties.sessionID)
          return next
        })
      }
    }),
    event.on("tui.session.select", () => updateActiveSession()),
  ]

  // Register sidebar slot for parent session
  slots.register({
    render: (props) => {
      const sessionID = props.session_id ?? activeSessionID()
      if (!sessionID) return null

      const children = childThreads(sessionID)
      if (children.length === 0) return null

      const t = theme.current

      return (
        <box flexDirection="column" paddingLeft={1} paddingRight={1}>
          <text fg={t.textMuted}>
            ── Subagents ({children.length}) ──
          </text>
          {children.slice(0, 5).map((child) => {
            const icon =
              child.status === "idle" || child.status === "complete"
                ? "✓"
                : child.status === "busy"
                  ? "⟳"
                  : child.status === "error"
                    ? "✗"
                    : "·"
            const title = child.info?.title ?? child.info?.slug ?? child.id.slice(0, 8)
            const preview = child.preview?.split("\n")[0]?.slice(0, 80) ?? ""
            return (
              <box flexDirection="column" paddingLeft={1}>
                <text>
                  {icon} {title}
                </text>
                {preview ? (
                  <text fg={t.textMuted} paddingLeft={2}>
                    {preview}
                  </text>
                ) : null}
              </box>
            )
          })}
          {children.length > 5 ? (
            <text fg={t.textMuted} paddingLeft={1}>
              … {children.length - 5} more
            </text>
          ) : null}
        </box>
      )
    },
  })

  lifecycle.onDispose(() => {
    for (const unsub of unsubs) unsub()
    setThreads(new Map())
  })
}

export default { id: "opencode-subagent-threads", tui }
