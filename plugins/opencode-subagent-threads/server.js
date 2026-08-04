/**
 * opencode-subagent-threads — server plugin
 *
 * Exposes tools to query subagent (child) session status from within the
 * current session. The companion TUI plugin renders these as compact inline
 * blocks in the parent session sidebar.
 */

import { tool } from "@opencode-ai/plugin"

export const server = async (input) => {
  const { client, directory } = input

  return {
    tool: {
      subagent_threads: tool({
        description:
          "List child subagent sessions spawned from the current session. " +
          "Returns session IDs, titles, status, and latest output preview.",
        args: {
          parentSessionID: tool.schema
            .string()
            .optional()
            .describe(
              "Parent session ID. Defaults to the current session.",
            ),
        },
        async execute(args, ctx) {
          const parentID = args.parentSessionID ?? ctx.sessionID
          try {
            const result = await client.session.list({
              query: { directory },
              throwOnError: true,
            })
            const sessions = result.data ?? []
            const children = sessions.filter(
              (s) => s.parentID === parentID,
            )
            if (children.length === 0) {
              return "No active subagent threads for this session."
            }

            const lines = await Promise.all(
              children.map(async (s) => {
                // Get latest assistant text
                let preview = ""
                try {
                  const msgs = await client.session.messages({
                    path: { id: s.id },
                    query: { directory },
                    throwOnError: true,
                  })
                  const lastAssistant = [...(msgs.data ?? [])]
                    .reverse()
                    .find((m) => m.info?.role === "assistant")
                  if (lastAssistant) {
                    const texts = lastAssistant.parts
                      ?.filter(
                        (p) =>
                          p.type === "text" &&
                          typeof p.text === "string",
                      )
                      .map((p) => p.text)
                    if (texts?.length) {
                      preview =
                        texts[texts.length - 1].slice(0, 120)
                    }
                  }
                } catch {}

                const diff = s.summary
                  ? `+${s.summary.additions}/-${s.summary.deletions}`
                  : "…"
                return [
                  `  ${s.id}`,
                  `    title:  ${s.title ?? s.slug}`,
                  `    diff:   ${diff}`,
                  `    latest: ${preview || "(no output yet)"}`,
                ].join("\n")
              }),
            )

            return [
              `Subagent threads (${children.length}):`,
              "",
              ...lines,
            ].join("\n")
          } catch (err) {
            return `Error: ${err.message ?? err}`
          }
        },
      }),
    },
  }
}

export default { id: "opencode-subagent-threads", server }
