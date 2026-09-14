# Verification

Report only what you ran, with the real result. A tier with no command is `skipped`, never `✓`.

## Tiers

| Tier | What | When |
|---|---|---|
| T1 | `commands.typecheck`, `commands.lint`, `commands.build` | every code change |
| T2 | `commands.test` scoped to touched units (shared units must have tests) | every code change |
| T3 | tests of every call site of a changed shared unit | a shared unit's code or API changed |
| T4 | `commands.e2e` or extension point `e2e` | `/reusable-dev:reuse-verify` only |

## Finding call sites (T3)

1. Use LSP find-references on the exported symbol if an LSP tool is available.
2. Otherwise grep for the import path without extension (e.g. `shared/lib/money`) and for the symbol name.
3. For each caller, run its colocated test file(s) (`*.test.*`, `*.spec.*`, `__tests__/`). If the test runner cannot target files, run the full `commands.test` once.
4. Caller with no test → list it under Notes as `untested call site: <path>`.

## Report format

```
Verified: T1 typecheck ✓ lint skipped (no command) · T2 4 tests ✓ · T3 2 call sites, 3 tests ✓
```
Failure: `T2 1 failing (money.test.ts: formats USD)` and stop to debug — do not claim done.
Not applicable: `T3 n/a (no shared unit changed)`. Touched unit without tests: `T2 no tests for <path>` (and add the test if the unit is shared).

## Built-in fallbacks (used when the extension point is empty or its skill is missing)

**test** — Write the test for the shared unit before the code: cover the default behavior, each variant/option, and the backward-compatible path. Run it and see it fail for the right reason, then implement.

**verify** — Before any "done" statement: run the configured commands for T1–T3 now, read the output, and put the numbers in the report. A configured command that cannot start (missing or broken binary) is reported as `Tn could not run (<error>)` and listed in Notes — never `✓`, never silently swapped for a different command.

**debug** — Read the full failure. Reproduce it with one command. Find the cause in the changed unit before editing anything. Change one thing, rerun. Never weaken or delete an assertion to get green. An intended behavior change may update the changed unit's own tests (T2), noted in Notes. A failing call-site test (T3) is never edited to pass: make the change backward compatible or update the calling code, and list each updated call site in Notes.

**review** — For a changed shared API: (1) every existing call compiles and behaves the same, or is updated in this change; (2) new props/params are optional with defaults; (3) removed/renamed items are deprecated, not deleted; (4) registry row updated.
