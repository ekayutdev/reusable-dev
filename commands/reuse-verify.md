---
description: Run the full verification ladder T1–T4 for current changes and report real results
argument-hint: "[path or 'all']"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Skill", "Agent"]
---

# Reuse verify

Scope: "$ARGUMENTS" (empty → files changed vs `HEAD` per `git status --porcelain`; not a git repo → `all`)

1. Read `.claude/reusable-dev.md` (missing → detect values per `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md` without writing the file, and add `config not saved — run /reusable-dev:reuse-setup` to Notes) and `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/verification.md`.
2. T1: run each non-empty `commands.typecheck`, `commands.lint`, `commands.build`. Empty → `skipped (no command)`.
3. T2: run `commands.test` for the scope. Empty → `skipped (no command)`.
4. T3: for each changed shared unit in scope, find call sites and run their tests per verification.md. No changed shared units → `T3 n/a (no shared unit changed)`.
5. T4: extension point `e2e` skills (invoke in order) or `commands.e2e`. Neither → `skipped (no e2e configured)`. A listed e2e skill that is not installed → use `commands.e2e` and add `skill <name> not installed → fallback` to Notes.
6. On any failure: stop the ladder, apply extension point `debug` (fallback in verification.md), and report the failure — do not continue to later tiers. A command that cannot start → `Tn could not run (<error>)`, stop the ladder like a failure. Tiers after the stop print `not run (stopped at Tn)`.
7. Output exactly:
```
Verified: T1 … · T2 … · T3 … · T4 …
Notes: …
```
Never print ✓ for a tier whose command did not run.
