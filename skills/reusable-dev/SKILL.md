---
name: reusable-dev
description: Use when about to create or modify a UI component, hook/composable, function, utility, service, or module in an application codebase, or when planning tasks that will. Finds existing reusable code first, decides Reuse → Extend → Compose → Create, applies design rules for the project's stack and UI library, verifies with typecheck/lint/tests including call sites of changed shared code, and keeps a reuse registry. Thai triggers - สร้าง component, เขียน function, เพิ่มปุ่ม, เพิ่มฟีเจอร์, reuse, shared component, โค้ดซ้ำ. Not for docs-only, config-only, or other non-code edits.
---

# Reusable Dev

Make components and functions easy to find, reuse, and change safely. This skill owns the reuse workflow and works without any other plugin.

## The rule

Before creating or changing a component, hook/composable, function, utility, service, or module, run the workflow. No new unit without a `Reuse decision:` line. "Writing a new one is faster" is the exact thought this skill exists to stop — Discover takes under a minute.

## Workflow

### 0. Load config
Read `.claude/reusable-dev.md`. Missing → follow "Missing config" in `references/config-format.md`.

### 1. Discover
1. Grep the registry file (config `registry`) for the thing you need plus 2–3 synonyms (button/btn/action · date/format/time · price/money/currency).
2. Confirm each hit's path exists. Missing → Notes: `registry stale — run /reusable-dev:reuse-registry --sync`.
3. Grep `shared_paths` and the whole source tree (`src/`, `app/`, `components/`, `composables/`, `lib/`, `apps/*`, `packages/*` — whichever exist; skip `node_modules` and build output) for the same terms and for similar function bodies or prop names. Duplicates inside feature folders count.
4. `ui_lib` set → check its primitives directory, then its CLI registry (`references/ui-libs/<ui_lib>.md`).

### 2. Decide
Pick the FIRST option that works, and say why earlier options do not:
1. **Reuse** — use the existing unit as is.
2. **Extend** — add an optional prop/parameter (or variant) with a default; existing call sites unchanged.
3. **Compose** — build a new unit from existing ones.
4. **Create** — new unit. One use → feature folder. Move to shared only when the second or third real use appears (Rule of Three); when you find two local copies and need a third, extract to shared and replace the copies.

### 3. Design
Load only what applies:
- UI → `references/component-design.md`; logic → `references/function-design.md` (these rules always apply, also when a `design` skill is configured)
- `references/stacks/<stack>.md` if present — when `stack` is a path map, use the entry whose path contains the file you are changing (unknown stack → general rules; Notes: `no stack reference for <stack> — /reusable-dev:reuse-setup can add one`)
- `references/ui-libs/<ui_lib>.md` if `ui_lib` is set
- Extension points `design`, `test` → `references/integration.md`
New or changed shared unit → write its test first.

### 4. Verify
Run T1–T3 per `references/verification.md` (extension points `verify`, `debug`). Never report a tier you did not run.

### 5. Register
Created a shared unit or changed a shared API → update its registry row (`references/registry-format.md`). Changed a shared API → extension point `review`.

## When planning instead of coding

Writing a design or implementation plan (with any planning skill or none): do Discover + Decide for each task and put a `Reuse decision:` line in every task that creates or changes code. Implementers who never load this skill still see it.

## Report — always end with

```
Reuse decision: <Reuse|Extend|Compose|Create> <unit> (<path>) — <one-line why>
Verified: T1 … · T2 … · T3 …   (a tier that does not apply: `T3 n/a (no shared unit changed)`; no command: `T1 skipped (no command)`)
Notes: <fallbacks, skipped tiers, stale registry, config not saved — or "none">
```
One `Reuse decision:` line per unit touched.

## Red flags

| Thought | Reality |
|---|---|
| "User said urgent, skip the search" | Discover is the fast path. Do it, keep it short. |
| "A new DangerButton is simpler" | A variant on Button is Extend. |
| "Put it in shared, it might be reused" | One use = feature folder. |
| "There are two copies already, a third is fine" | Third use = extract to shared now. |
| "Tests probably pass" | Run them, or write `skipped (no command)`. |
| "Loosen the call-site test so it passes" | Keep the API backward compatible or update the caller. |
