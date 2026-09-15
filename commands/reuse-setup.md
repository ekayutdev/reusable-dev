---
description: Detect the project's stack, UI library, commands, and optional extension skills, then write .claude/reusable-dev.md
argument-hint: "[--reset]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "AskUserQuestion"]
---

# Reuse setup

Arguments: "$ARGUMENTS"

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md`. This command always writes the config (step 7), also in non-interactive runs — the "do not write" rule in config-format.md "Missing config" applies only to the skill's automatic step 0.
2. Detect every key using its detection table (read package.json, lockfiles, framework config files, components.json, tsconfig, go.mod/pyproject.toml/composer.json/Cargo.toml/Package.swift/*.sln/*.csproj). Stacks outside the detection table: use the ecosystem name (`go` for go.mod, `php` for composer.json without Laravel, `rust` for Cargo.toml without axum, `swift` for Package.swift or `*.xcodeproj` without SwiftUI, `fsharp` for `*.fsproj` without `*.csproj`) and treat it as a stack without a reference file (step 4).
3. Extension points: read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/integration.md`. For each point, list skills or agents from YOUR available skills/agents whose purpose matches the point (the example column is a hint, not a requirement). Only suggest skills or agents that are actually available.
4. Stack reference: if the detected stack has no `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/stacks/<stack>.md`, offer to write one into the project at `.claude/reusable-dev/stacks/<stack>.md` from `stacks/_template.md` (the skill reads that location too).
5. Ask ONE AskUserQuestion round (max 4 questions) covering: undetected keys, extension-point choices grouped (e.g. design+test, verify+debug+review, plan+e2e; offer the top available suggestions), the stack file offer, and — if the `registry` file does not exist — whether to build it now. When the topics exceed 4 questions, merge the stack-file and registry offers into one multi-select "also do" question. If AskUserQuestion is unavailable or the arguments say non-interactive, take detected values and leave extension points `[]`.
6. Existing `.claude/reusable-dev.md` and no `--reset`: start from its current values; only propose keys that are missing or whose detected value differs; keep every existing `skills` entry and hand-set key unless the user changes it in step 5; show the diff before writing and keep the body text. `--reset`: overwrite with detected values.
7. Write the file with every key from the schema, including all seven `skills` points. Any write inside `.claude/` (this config or a stack file) needs the user's permission in Claude Code; if a write is denied, print the full config — and for a denied stack file, the stack file content — in a fenced block and tell the user where to save it; never retry through Bash or another tool.
8. Registry: if the `registry` file does not exist and the user chose to build it in step 5 (non-interactive: build it), read `${CLAUDE_PLUGIN_ROOT}/commands/reuse-registry.md` and follow its steps with `--sync`; if that file is not available, create the empty template from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/registry-format.md`.
9. Print the final config and the next step: "reusable-dev will now run automatically when you create or change components and functions."
