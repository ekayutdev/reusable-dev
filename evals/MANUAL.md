# Manual checks — reusable-dev with superpowers installed

`claude plugin eval` cannot load plugins from outside this repo, so co-operation with superpowers is checked by hand before each release.

## Setup

1. Copy `evals/fixtures/react-shadcn` to a scratch directory.
2. In the copy, edit `.claude/reusable-dev.md`: set `skills.test: [superpowers:test-driven-development]` and `skills.verify: [superpowers:verification-before-completion]`.
3. Install and enable superpowers, then start `claude --plugin-dir <path-to-this-repo>` in the copy.

The fixture has no dependencies installed and all `commands` empty, so every tier that needs a command is expected to report `skipped (no command)` — never ✓.

| # | Do | Pass when |
|---|---|---|
| M1 | "/superpowers:brainstorming add a customers list page with delete per row" → approve through to the plan | The design reuses or extends DataTable and extends Button; every code task in the written plan has its own `Reuse decision:` line |
| M2 | Execute the plan with superpowers:subagent-driven-development | No new Button/Table component files; every implementer receives its task's `Reuse decision:` line — since superpowers 6.3.0 the dispatch prompt carries a task-brief *path*, so check the brief the implementer read (or its transcript), not the prompt text |
| M3 | During M2, open each implementer subagent transcript | `Skill(superpowers:test-driven-development)` is called at most once per implementer (reusable-dev adds requirements instead of invoking it again), and the shared Button test covers the new variant |
| M4 | Before completion, read the final report | `Verified:` shows T3 for each changed shared unit with callers (e.g. `formatDate` → OrdersPage, InvoicesPage; DataTable only if it changed) as run or `skipped (no command)` — never ✓ without output; callers without tests appear in `Notes:` as `untested call site: <path>` |
| M5 | Disable superpowers; in a fresh copy with Setup step 2 applied, ask "add a customers page with a delete button per row" (coding, not planning) | Work completes with `Reuse decision:` lines; no errors about missing skills; `Notes:` has `skill <name> not installed → fallback` once per configured superpowers skill it reached |
| M6a | Fresh copy, `rm .claude/reusable-dev.md`, run `/reusable-dev:reuse-setup`, deny the write prompt | The full config is printed in a fenced block with the path to save it; no Bash/Edit retry |
| M6b | Fresh copy, `rm .claude/reusable-dev.md`, ask "add a delete button to CustomerCard", deny any write prompt for the config | No retry through another tool; the button work continues; Notes contain exactly `config not saved — run /reusable-dev:reuse-setup` |
| M7 | Fresh copy, `rm .claude/reusable-dev.md`, ask "add a delete button to CustomerCard", answer the setup questions, allow the write; then start a new session and ask "add an edit button to CustomerCard" | First session asks once and writes `.claude/reusable-dev.md`; second session asks no setup questions |

## Results

| Date | Claude Code | superpowers | M1 | M2 | M3 | M4 | M5 | M6a | M6b | M7 | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-09-18 | 2.1.276 | 6.3.0 | ✓* | ✓* | ✓ | ✗ | | | | | All four run headless (`claude -p`) instead of interactively; the installed `reusable-dev` was disabled so `--plugin-dir` loaded only the working tree. **M1 ✓*** — 4/4 code tasks carry their own `Reuse decision:` line; Task 1 extends Button's `variant` enum, Task 2 adds optional `rowActions` to DataTable. Interactive M1 still unrun. **M2 ✓*** — no new Button/Table component file (both extended in place, `OrdersPage`/`InvoicesPage` untouched since baseline), but the literal criterion no longer matches superpowers 6.3.0: implementer prompts carry a *task-brief file path*, not inline task text, so `Reuse decision:` appears in none of the 4 dispatch prompts. It does reach every implementer — each of the 4 implementer transcripts contains it via the brief. Criterion wording needs updating. **M3 ✓** — 0 `Skill(...)` calls per implementer (≤1 as required) and `button.test.tsx` covers `destructive` (3 refs); note the TDD skill was never invoked at all, its requirements arrived as brief text. **M4 ✗** — under subagent-driven-development the final message contained **no** reusable-dev report block: zero `Reuse decision:`, zero `Verified:`, zero `Notes:`. An earlier confounded run of the same plan (implementers diverted to the hermes CLI, controller verifying directly) *did* emit the block with `Verified: T1/T2/T3 skipped (no command)` — correct, never a bare ✓ — but still omitted `untested call site:` for DataTable's two untested callers. So the report block is emitted when the main agent does the work and disappears when it delegates. **Environment finding:** `claude plugin disable hermes-offload` does NOT stop its hook — the hook is registered directly in `~/.claude/settings.json` (`PreToolUse` → `hooks/hz-offload-redirect.sh`). Use `HERMES_OFFLOAD=0` (script line 54) or write `off` to `~/.hermes/offload.state`. The first M2 attempt was invalid because of this: 7 reviewer subagents, 0 implementer subagents. |
