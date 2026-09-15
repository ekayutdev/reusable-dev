# Config format — `.claude/reusable-dev.md`

Committed to git so the whole team shares one convention. YAML frontmatter + free-text body (team conventions in prose).

```yaml
---
stack: react-next            # react-next | vue-nuxt | sveltekit | node-ts | nestjs | fastapi | django | python | laravel | rust-axum | swiftui | dotnet, or an ecosystem name (go | php | rust | swift | fsharp, no reference file), or a path map for monorepos:
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

Backend and native frameworks (rows 4–9) come before bare UI-library deps (row 10) and generic package.json rows (11–12) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).

| # | Signal | Value |
|---|---|---|
| 1 | `next.config.*` or `"next"` in package.json deps | `stack: react-next` |
| 2 | `nuxt.config.*` or `"nuxt"` in deps | `stack: vue-nuxt` |
| 3 | `"@sveltejs/kit"` in deps (with or without `svelte.config.*`) | `stack: sveltekit` |
| 4 | `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` | `stack: django` |
| 5 | `fastapi` in `pyproject.toml` / `requirements*.txt` | `stack: fastapi` |
| 6 | `artisan`, or `laravel/framework` in `composer.json` | `stack: laravel` |
| 7 | `axum` in any `Cargo.toml` in the repo (root, member, or excluded crate) | `stack: rust-axum` |
| 8 | `Package.swift` or `*.xcodeproj` present and `import SwiftUI` in a source file | `stack: swiftui` |
| 9 | `*.sln` / `*.slnx` at the root, or `*.csproj` at the root, in `*/` or in `src/*/` — and at least one `*.csproj` in the repo | `stack: dotnet` |
| 10 | `"react"` in deps without next → `stack: react-next`; `"vue"` in deps without nuxt → `stack: vue-nuxt` | see signal |
| 11 | `"@nestjs/core"` in deps or `nest-cli.json` | `stack: nestjs` |
| 12 | package.json with another server framework (`express`, `fastify`, `hono`) or no UI framework, and no `pyproject.toml` / `requirements*.txt` / `setup.py` / `composer.json` / `Cargo.toml` / `Package.swift` / `*.sln` / `*.slnx` / `*.csproj` at the same level (tsconfig.json optional) | `stack: node-ts` |
| 13 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `stack: python` |
| – | `components.json` + react / vue / svelte | `ui_lib: shadcn-react` / `shadcn-vue` / `shadcn-svelte` |
| – | package.json `scripts` named `typecheck`/`type-check`, `lint`, `test`, `build`, `e2e`/`test:e2e` | `commands.*` = `<pm> run <script>` using the lockfile's package manager |
| – | Python: `pytest` in deps → `commands.test: pytest`; else `manage.py` → `python3 manage.py test`; else `python3 -m unittest` | `commands.test` |
| – | Laravel: `vendor/bin/pest` exists → `commands.test: vendor/bin/pest`; else `php artisan test` — also when `vendor/` is not installed yet; record the framework command, not a workaround script | `commands.test` |
| – | Rust: `cargo test` | `commands.test` |
| – | Swift: `Package.swift` → `swift test`; only `*.xcodeproj` → `xcodebuild test -scheme <scheme>` with a scheme from `xcodebuild -list`; scheme unknown → ask, non-interactive → `""` | `commands.test` |
| – | .NET: `commands.test: dotnet test`; `commands.build: dotnet build` | `commands.test`, `commands.build` |
| – | Multiple `apps/*` or `packages/*` with different signals | path map for `stack` |

`stack: python` loads `stacks/python.md`.

A project stack file may live at `.claude/reusable-dev/stacks/<stack>.md` (written by `/reusable-dev:reuse-setup`); the skill reads that location too. Shared paths: prefer existing dirs in this order — `src/shared/ui`, `src/components/shared`, `src/components/common`, `packages/ui/src` for components; `src/shared/lib`, `src/lib`, `packages/shared/src` for functions. Ignore the ui-lib primitives dir (`components/ui`) — it is covered by `ui_lib`. NestJS functions shared paths (first that exists): `src/common`, `libs/shared/src`.

## Source roots by language

| Language | Discover roots (whichever exist) | Skip |
|---|---|---|
| JS/TS | `src/`, `app/`, `lib/`, `components/`, `composables/`, `hooks/`, `utils/`, `stores/`, `server/`, `shared/`, `apps/*`, `packages/*`, `libs/*` | `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `.svelte-kit` |
| Python | `src/`, `app/`, every root package with `__init__.py` or `apps.py` | `.venv`, `venv`, `__pycache__`, `migrations/`, `.pytest_cache`, `.mypy_cache` |
| PHP | `app/`, `src/`, `resources/views/components/`, `packages/*` | `vendor/`, `storage/`, `bootstrap/cache/`, `node_modules` |
| Rust | `src/`, `crates/*` | `target/` |
| Swift | `Sources/*`, `Packages/*`, the app target folder | `.build/`, `DerivedData/` |
| C# | `src/*`, `tests/*`, project folders next to the `*.sln` / `*.slnx` | `bin/`, `obj/`, `node_modules` |

Python shared paths (first that exists, as `shared_paths.functions`): `common/`, `core/`, `shared/`, `app/shared/`, `src/<pkg>/shared/`; `shared_paths.components` is `common/templates` for Django, otherwise `""`.

Laravel shared paths (first that exists): functions `app/Support`, `app/Actions`; components `resources/views/components`. Rust: functions `crates/shared/src`, `src/shared`; components `""`. SwiftUI: functions `Sources/Shared`, `Packages/Shared/Sources`; components `Sources/DesignSystem`, `Packages/DesignSystem/Sources`. .NET: functions `src/Shared`, `src/*.Shared`; components `src/*/Components/Shared`, `src/*.Components`.

## Missing config (skill step 0)

1. Detect every key above that has a signal.
2. Ask at most 3 questions in ONE AskUserQuestion call (only via the AskUserQuestion tool), only for keys with no signal (usually `shared_paths` and `error_style`). Offer the detected default as the first option.
3. Only when step 2 was done through AskUserQuestion (or nothing needed asking and AskUserQuestion is available): Write `.claude/reusable-dev.md` with all keys; `skills` all `[]` (full skill wiring is `/reusable-dev:reuse-setup`).
4. AskUserQuestion is not in your tools (non-interactive run), the user skips, or a write to the config is denied → do not write or create `.claude/reusable-dev.md`, do not ask questions in your reply text; continue with detected values and defaults (`error_style: throw`, `registry: docs/reuse-registry.md`) and add exactly `config not saved — run /reusable-dev:reuse-setup` to the report Notes.
5. Never ask again in a project where the file exists. Changes happen by editing the file or re-running `/reusable-dev:reuse-setup`.
