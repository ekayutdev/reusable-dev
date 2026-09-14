# Manual checks — reusable-dev with superpowers installed

`claude plugin eval` cannot load plugins from outside this repo, so co-operation with superpowers is checked by hand before each release.

Setup: a scratch copy of `evals/fixtures/react-shadcn`, superpowers installed and enabled, then start `claude --plugin-dir <path-to-this-repo>` in that copy.

| # | Do | Pass when |
|---|---|---|
| M1 | "/superpowers:brainstorming add a customers list page with delete per row" → approve through to the plan | Design mentions DataTable reuse and Button extend; every code task in the written plan has a `Reuse decision:` line |
| M2 | Execute the plan with superpowers:subagent-driven-development | No new Button/Table component files; implementer prompts contain the `Reuse decision:` lines |
| M3 | During M2, observe TDD | reusable-dev does not invoke test-driven-development a second time; shared Button test covers the new variant |
| M4 | Before completion | Verification output includes T3 call sites for Button |
| M5 | Uninstall/disable superpowers and repeat M1 without brainstorming ("plan a customers page") | Plan still has `Reuse decision:` lines; no errors about missing skills |
| M6 | During M1–M2, try a `.claude/reusable-dev.md` write (no config yet) | Claude Code shows a permission prompt; on deny the skill/command prints the config instead of retrying via Bash |

Record date, Claude Code version, superpowers version, and pass/fail per row at the bottom of this file.
