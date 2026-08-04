# LSP / AST (opencode-plugin-ast-lsp)

Plugin: `opencode-plugin-ast-lsp`, installed globally. Requires `bun` on PATH
(bun 1.3.14 present). Language servers auto-install on first use.

## Tools

- `lsp_inspect` — symbol info at a position (type, docs, signature).
- `lsp_discover` — discover symbols in a file/project.
- `lsp_usages` — find references / call sites.
- `lsp_diagnostics` — errors/warnings for a file or project. Run after every edit.
- `lsp_rename` — symbol rename. Always dry-run first, review the edit set, then apply.
- `ast_grep_search` — structural (AST-aware) code search.
- `ast_grep_replace` — structural rewrite. Always dry-run before applying.

## Validation checklist (before declaring a change done)

1. lsp_inspect the symbol being changed.
2. Check its definition.
3. lsp_usages for all references.
4. Make the edit.
5. lsp_diagnostics on changed files — zero new errors.
6. lsp_rename dry-run (if renaming) -> review -> apply.
7. ast_grep_search to confirm no stray structural matches remain.
8. ast_grep_replace dry-run -> review -> apply (for structural refactors).

## Scope and limitations

- Languages: TypeScript / JavaScript only, plus ESLint integration.
- Other languages (e.g. Rust) are NOT covered — use cargo via the tester agent.
- Windows + bun behavior should be verified on first LSP use: the first call may take
  time while the language server downloads and installs.
- If a language server fails to start, check `bun --version` on PATH and retry.

## Preference order

For semantic questions use lsp_* tools first, then ast_grep_search, then plain
grep/glob as a last resort (see rules/exploration.mdc).
