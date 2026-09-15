# Config format — `.claude/reusable-dev.md`

Committed to git so the whole team shares one convention. YAML frontmatter + free-text body (team conventions in prose).

```yaml
---
stack: react-next            # react-next | vue-nuxt | sveltekit | node-ts | nestjs | fastapi | django | python, or an ecosystem name (go | php, no reference file), or a path map for monorepos:
# stack: { "apps/web": react-next, "apps/api": node-ts }
ui_lib: shadcn-react         # shadcn-react | shadcn-vue | shadcn-svelte | ""
shared_paths:
  components: src/shared/ui  # "" if the project has no UI
  functions: src/shared/lib
commands:                    # "" = not available → that tier is reported as skipped
  typecheck: "tsc --noEmit"
  lint: "eslint ."
  test: "vitest run"
  build: "vite build"
  e2e: ""
error_style: throw           # throw | result
registry: docs/reuse-registry.md
skills:                      # optional extension points; [] = built-in fallback
  design: []
  test: []
  verify: []
  debug: []
  review: []
  plan: []
  e2e: []
---
```

## Detection signals

Use the first row that matches, top to bottom.

| # | Signal | Value |
|---|---|---|
| 1 | `next.config.*` or `"next"` in package.json deps | `stack: react-next` |
| 2 | `nuxt.config.*` or `"nuxt"` / `"vue"` in deps | `stack: vue-nuxt` |
| 3 | `svelte.config.*` or `"@sveltejs/kit"` in deps | `stack: sveltekit` |
| 4 | `"react"` in deps without next | `stack: react-next` |
| 5 | `"@nestjs/core"` in deps or `nest-cli.json` | `stack: nestjs` |
| 6 | package.json with another server framework (`express`, `fastify`, `hono`) or no UI framework (tsconfig.json optional) | `stack: node-ts` |
| 7 | `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` | `stack: django` |
| 8 | `fastapi` in `pyproject.toml` / `requirements*.txt` | `stack: fastapi` |
| 9 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `stack: python` |
| – | `components.json` + react / vue / svelte | `ui_lib: shadcn-react` / `shadcn-vue` / `shadcn-svelte` |
| – | package.json `scripts` named `typecheck`/`type-check`, `lint`, `test`, `build`, `e2e`/`test:e2e` | `commands.*` = `<pm> run <script>` using the lockfile's package manager |
| – | Python: `pytest` in deps → `commands.test: pytest`; else `manage.py` → `python manage.py test`; else `python3 -m unittest` | `commands.test` |
| – | Multiple `apps/*` or `packages/*` with different signals | path map for `stack` |

`stack: python` loads `stacks/python-core.md`.

A project stack file may live at `.claude/reusable-dev/stacks/<stack>.md` (written by `/reusable-dev:reuse-setup`); the skill reads that location too. Shared paths: prefer existing dirs in this order — `src/shared/ui`, `src/components/shared`, `src/components/common`, `packages/ui/src` for components; `src/shared/lib`, `src/lib`, `packages/shared/src` for functions. Ignore the ui-lib primitives dir (`components/ui`) — it is covered by `ui_lib`.

## Source roots by language

| Language | Discover roots (whichever exist) | Skip |
|---|---|---|
| JS/TS | `src/`, `app/`, `lib/`, `components/`, `composables/`, `hooks/`, `utils/`, `stores/`, `server/`, `shared/`, `apps/*`, `packages/*` | `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `.svelte-kit` |
| Python | `src/`, `app/`, every root package with `__init__.py` or `apps.py` | `.venv`, `venv`, `__pycache__`, `migrations/`, `.pytest_cache`, `.mypy_cache` |

Python shared paths (first that exists): `common/`, `core/`, `shared/`, `app/shared/`, `src/<pkg>/shared/`.

## Missing config (skill step 0)

1. Detect every key above that has a signal.
2. Ask at most 3 questions in ONE AskUserQuestion call (only via the AskUserQuestion tool), only for keys with no signal (usually `shared_paths` and `error_style`). Offer the detected default as the first option.
3. Only when step 2 was done through AskUserQuestion (or nothing needed asking and AskUserQuestion is available): Write `.claude/reusable-dev.md` with all keys; `skills` all `[]` (full skill wiring is `/reusable-dev:reuse-setup`).
4. AskUserQuestion is not in your tools (non-interactive run), the user skips, or a write to the config is denied → do not write or create `.claude/reusable-dev.md`, do not ask questions in your reply text; continue with detected values and defaults (`error_style: throw`, `registry: docs/reuse-registry.md`) and add exactly `config not saved — run /reusable-dev:reuse-setup` to the report Notes.
5. Never ask again in a project where the file exists. Changes happen by editing the file or re-running `/reusable-dev:reuse-setup`.
