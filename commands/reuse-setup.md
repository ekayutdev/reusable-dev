---
description: Detect the project's stack, UI library, commands, and optional extension skills, then write .claude/reusable-dev.md
argument-hint: "[--reset]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "AskUserQuestion"]
---

# Reuse setup

Arguments: "$ARGUMENTS"

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md`.

This command always writes the config (step 7), also in non-interactive runs — the "do not write" rule in config-format.md "Missing config" applies only to the skill's automatic step 0.

2. Detect every key using its detection table (read package.json, lockfiles, framework config files, components.json, tsconfig, go.mod/pyproject.toml/composer.json).
3. Extension points: read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/integration.md`. For each point, list skills from YOUR available-skills list whose purpose matches the point (the example column is a hint, not a requirement). Only suggest skills that are actually available.
4. Stack reference: if the detected stack has no `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/stacks/<stack>.md`, offer to write one into the project at `.claude/reusable-dev/stacks/<stack>.md` from `stacks/_template.md`.
5. Ask ONE AskUserQuestion round (max 4 questions) covering: undetected keys, extension-point choices (multi-select per point group), stack file offer. If AskUserQuestion is unavailable or the arguments say non-interactive, take detected values and leave extension points `[]`.
6. Existing `.claude/reusable-dev.md` and no `--reset`: show a diff of the proposed changes and keep the existing body text; `--reset`: overwrite.
7. Write the file with every key from the schema, including all seven `skills` points. Writing inside `.claude/` needs the user's permission in Claude Code; if the write is denied, print the full config in a fenced block and tell the user to save it as `.claude/reusable-dev.md` — never retry through Bash or another tool.
8. Registry: if the `registry` file does not exist, ask whether to create it now by running `/reusable-dev:reuse-registry --sync` (non-interactive: create the empty template from `registry-format.md`).
9. Print the final config and the next step: "reusable-dev will now run automatically when you create or change components and functions."
