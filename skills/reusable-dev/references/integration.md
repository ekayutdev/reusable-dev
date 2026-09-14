# Extension points and working with other skills

reusable-dev depends on roles, not on specific skills. Nothing here is required.

## Extension points

| Point | Runs at | Example skills (optional) | Fallback |
|---|---|---|---|
| `design` | workflow step 3 | `mattpocock-skills:codebase-design`, `frontend-design:frontend-design` | none needed — component-design.md / function-design.md always apply; a `design` skill adds to them |
| `test` | step 3, shared units | `superpowers:test-driven-development`, `mattpocock-skills:tdd` | verification.md → test |
| `verify` | step 4 | `superpowers:verification-before-completion` | verification.md → verify |
| `debug` | a test fails | `superpowers:systematic-debugging`, `mattpocock-skills:diagnosing-bugs` | verification.md → debug |
| `review` | shared API changed | `pr-review-toolkit:code-reviewer` (agent) | verification.md → review |
| `plan` | `/reusable-dev:reuse-audit` finds a large refactor | `superpowers:writing-plans` | numbered steps in the audit report |
| `e2e` | `/reusable-dev:reuse-verify` | `chrome-devtools-mcp:chrome-devtools`, `run` | `commands.e2e` |

## Rules

1. Empty list → use the fallback.
2. Listed skill (or agent) not in your available skills/agents → use the fallback and add `skill <name> not installed → fallback` to Notes once (name it exactly as configured, e.g. `skill nonexistent-plugin:super-tdd not installed → fallback`). Never stop the workflow for this.
3. Several skills in one list → invoke in order.
4. reusable-dev keeps ownership of the workflow; an invoked skill does only its point's job, then continue with the next step.
5. The point's skill (or another skill doing the same job) is already active in this session → do not invoke it again; add the reuse requirements below to what it is already doing.

## Reuse requirements to add when another process skill leads

| That skill is doing | Add |
|---|---|
| Brainstorming / design | Discover + Decide for each new unit; put the decisions in the design. |
| Writing a plan | A `Reuse decision:` line in every task that creates or changes code, naming the existing unit and path. |
| Executing a plan / dispatching subagents | Keep each task's `Reuse decision:` line in the text given to the implementer. |
| Test-driven development | Shared units: tests cover each variant/option and the backward-compatible path. |
| Verification before completion | T1–T3 including call sites. |
| Finishing a branch | Registry rows updated for every new or changed shared unit. |
