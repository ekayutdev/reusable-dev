---
description: Sync docs/reuse-registry.md with the exports in shared paths; optionally generate a shadcn registry.json
argument-hint: "[--sync] [--shadcn-registry]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "AskUserQuestion"]
---

# Reuse registry

Arguments: "$ARGUMENTS"

1. Read `.claude/reusable-dev.md` (missing → detection from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md`, not saved — run /reusable-dev:reuse-setup to save it; never write `.claude/reusable-dev.md` from this command) and `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/registry-format.md`.
2. Collect exports: under `shared_paths.components`, `shared_paths.functions`, the ui-lib primitives dir, and any `hooks`/`composables` dirs next to them. Skip test files and index/barrel files (register the real file).
3. For each export compute Name, Path, Purpose (from its doc comment or by reading the body — one line), API (props/params), Used by (grep import sites outside its file and tests), Notes.
4. Compare with the registry: `add` (export not in registry), `update` (API or Used by changed), `remove` (row path missing). Without `--sync`: print the diff table and stop. With `--sync`: show the diff, ask for confirmation once (skip asking and apply when AskUserQuestion is unavailable, when the arguments say non-interactive, or when invoked from /reusable-dev:reuse-setup, which already asked; if the user declines, write nothing), then write the registry, keeping section order and alphabetical rows.
5. `--shadcn-registry` and `ui_lib` starts with `shadcn`: generate the registry source for that port as described in its `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/ui-libs/<ui_lib>.md` "Cross-project sharing" section (rule S5), one item per shared pattern component, and print the exact command teammates run to install an item.
6. Report counts: `added N · updated N · removed N`.
