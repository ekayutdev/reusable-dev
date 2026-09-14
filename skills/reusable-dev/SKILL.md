---
name: reusable-dev
description: Use when about to create, modify, refactor, or extract a UI component, hook/composable, store, function, utility, service, or module in an application codebase, or when writing a design or implementation plan whose tasks will. Typical requests - add a button/modal/form, new helper or hook, change a component's props, refactor or move code into shared, duplicate code, reuse. Thai phrasing - สร้าง component, แก้ component, เขียน function, แก้ฟังก์ชัน, เพิ่มปุ่ม, เพิ่มหน้า, เพิ่มฟีเจอร์, refactor, รีแฟกเตอร์, แยก component, ย้ายไป shared, โค้ดซ้ำ, ใช้ซ้ำ, วางแผนงาน. Not for docs-only edits (README, markdown), config-only edits (package.json, .env, YAML/JSON, CI), questions that change no code, or other non-code edits.
---

# Reusable Dev

Make components and functions easy to find, reuse, and change safely. This skill owns the reuse workflow and works without any other plugin.

## The rule

Before creating or changing a component, hook/composable, function, utility, service, or module, run the workflow. No new unit without a `Reuse decision:` line. "Writing a new one is faster" is the exact thought this skill exists to stop — Discover takes under a minute.

## Workflow

### 0. Load config
Read `.claude/reusable-dev.md`. Missing → follow "Missing config" in `references/config-format.md`; never write the file unless AskUserQuestion was available.

### 1. Discover
1. Grep the registry file (config `registry`) for the thing you need plus 2–3 synonyms (button/btn/action · date/format/time · price/money/currency) (file missing → skip to 3; it is created in step 5).
2. Confirm each hit's path exists. Missing → Notes: `registry stale — run /reusable-dev:reuse-registry --sync`.
3. Grep `shared_paths` and the whole source tree (`src/`, `app/`, `lib/`, `components/`, `composables/`, `hooks/`, `utils/`, `stores/`, `server/`, `shared/`, `apps/*`, `packages/*` — whichever exist; skip `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `.svelte-kit`) for the same terms and for similar function bodies or prop names. Duplicates inside feature folders count.
4. `ui_lib` set → check its primitives directory, then its CLI registry (`references/ui-libs/<ui_lib>.md`).

### 2. Decide
Pick the FIRST option that works, and say why earlier options do not:
1. **Reuse** — use the existing unit as is.
2. **Extend** — add an optional prop/parameter (or variant) with a default; existing call sites unchanged.
3. **Compose** — build a new unit from existing ones.
4. **Create** — new unit. First or second use → feature folder. Third use (two copies found, a third needed) → extract to shared, replace every copy, report as Create with "third use" (Rule of Three). A unit inside another feature folder is a copy, never a Reuse target.

### 3. Design
Load only what applies:
- UI → `references/component-design.md`; logic → `references/function-design.md` (these rules always apply, also when a `design` skill is configured)
- `references/stacks/<stack>.md`, or the project's `.claude/reusable-dev/stacks/<stack>.md`, if present — when `stack` is a path map, use the entry with the longest path prefix of the file (planning: of the target directory); no match → general rules (unknown stack → general rules; Notes: `no stack reference for <stack> — /reusable-dev:reuse-setup can add one`)
- `references/ui-libs/<ui_lib>.md` if `ui_lib` is set and the file exists (missing → Notes: `no ui-lib reference for <ui_lib>`)
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
Verified: T1 <result> · T2 <result> · T3 <result>
Notes: <fallbacks, skipped tiers, stale registry, missing config — or none>
```
Tier result: counts with ✓, `skipped (no command)`, `n/a (<reason>)`, `could not run (<error>)`, or the failure (`references/verification.md`). Missing config note is exactly `config not saved — run /reusable-dev:reuse-setup`.
One `Reuse decision:` line per unit touched.
Changing an existing unit without an API change: `Reuse decision: Reuse <unit> (<path>) — internal change, API unchanged`; Discover is limited to its call sites.

## Red flags

|| Thought | Reality ||
||---|---|---|
|| "User said urgent, skip the search" | Discover is the fast path. Do it, keep it short. |
|| "A new DangerButton is simpler" | A variant on Button is Extend. |
|| "Put it in shared, it might be reused" | One use = feature folder. |
|| "There are two copies already, a third is fine" | Third use = extract to shared now. |
|| "Tests probably pass" | Run them, or write `skipped (no command)`. |
|| "Loosen the call-site test so it passes" | Keep the API backward compatible or update the caller. |
