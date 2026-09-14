# Registry format — default `docs/reuse-registry.md` (config `registry`)

One row per reusable unit so a single `grep -i <term>` returns path, API, and usage. Committed to git.

```markdown
# Reuse Registry

## UI · Primitives
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|

## UI · Patterns
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|

## Hooks · Composables
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|

## Services
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
```

## Columns

- **Name** — exported identifier.
- **Path** — repo-relative file path.
- **Purpose** — one line, starts with a verb, includes the words people would search for.
- **API** — props or parameters in backticks; `?` marks optional; enums as `a\|b`.
- **Used by** — number of import sites outside the unit's own file and tests. Count with grep on the import path.
- **Notes** — `pure`, `shadcn generated`, `shadcn modified: <what>`, `wraps <X>`, `deprecated → <Y>`.

## Rules

- Section choice: primitives = ui-lib or lowest-level UI; patterns = composed UI; hooks/composables = stateful logic without markup; functions = pure/domain logic; services = units that do IO.
- Keep rows sorted by Name within a section.
- A row whose Path no longer exists is stale: remove it during `/reusable-dev:reuse-registry --sync`, never during normal work (report it instead).
- Missing registry file: create it with the empty template above the first time a shared unit is added.
