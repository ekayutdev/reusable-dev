---
description: Scan for duplicated code and reuse-rule violations, report prioritized findings without editing
argument-hint: "[path]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Agent"]
---

# Reuse audit

Scope: "$ARGUMENTS"

1. Read `.claude/reusable-dev.md`. Missing → use detection from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md` without writing the file.
2. Scope: the argument path if given; otherwise `shared_paths` plus files changed in the last 20 commits (`git log --name-only -20 --pretty=format:`), existing files only.
3. Dispatch the `duplicate-finder` agent with: scope paths, `shared_paths`, `ui_lib`, `stack`, and references dir `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references`.
4. Do NOT edit or create files in this command.
5. Report:

```
## Reuse audit — <scope>
| # | Impact | Kind | Rule | Where | Suggestion |
|---|---|---|---|---|---|
```
Rows from the agent's FINDING lines, highest impact first. After the table: findings with 3+ locations or touching 5+ files are marked `large` — for those, say they should go through extension point `plan` (see `integration.md`) before any edit.

6. End with: "Which findings should I fix? (numbers, or 'none')". When the user picks, handle each picked finding through the reusable-dev skill workflow steps 2–5.
