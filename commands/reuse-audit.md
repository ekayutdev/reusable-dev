---
description: Scan for duplicated code and reuse-rule violations, report prioritized findings without editing
argument-hint: "[path]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Agent", "Edit", "Write", "Skill"]
---

# Reuse audit

Scope: "$ARGUMENTS"

1. Read `.claude/reusable-dev.md`. Missing → use detection from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md` without writing the file.
2. Scope: the argument path if given; otherwise `shared_paths` plus files changed in the last 20 commits and uncommitted changes (`git log --name-only -20 --pretty=format:` plus `git diff --name-only HEAD`, plus untracked files via `git ls-files --others --exclude-standard`), deduplicated, existing files only; git failure (no commits / not a repo) → `shared_paths` only.
3. Dispatch the `reusable-dev:duplicate-finder` agent with: scope paths, `shared_paths`, `ui_lib`, `stack`, and references dir `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references`.
4. Do NOT edit or create files in steps 1–5.
5. Report:

```
## Reuse audit — <scope>
| # | Impact | Kind | Rule | Similarity | Where | Suggestion |
|---|---|---|---|---|---|---|
```
Impact is the agent's numeric 1–5 and Kind is copied exactly (lowercase: duplicate, rule, untested-shared, handwritten-primitive). Rows from the agent's FINDING lines, highest impact first. Findings with 3+ locations or touching 5+ files are marked `large`. For large findings read `skills.plan` from the config and `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/integration.md`: a listed plan skill that is available → say it will be used before any edit; empty or not installed → add a numbered refactor step list for each large finding under the table (and for a missing skill add `skill <name> not installed → fallback` to a `Notes:` line). No large findings → say so in one line.

6. End with: "Which findings should I fix? (numbers, or 'none')". When the user picks, edits happen only here, after the pick: handle each picked finding through the reusable-dev skill workflow steps 2–5. Picked findings marked `large` go through the plan skill from `skills.plan` (or the numbered fallback steps) before any edit.
