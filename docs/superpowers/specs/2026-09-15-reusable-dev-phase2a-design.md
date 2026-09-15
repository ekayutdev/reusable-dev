# reusable-dev Phase 2a — NestJS, FastAPI, Django — Design Spec

- **วันที่:** 2026-09-15
- **สถานะ:** Approved design, รอรีวิว spec
- **ต่อจาก:** `docs/superpowers/specs/2026-09-14-reusable-dev-plugin-design.md` (Phase 1, merged)

## 1. เป้าหมาย

เพิ่ม stack `nestjs`, `fastapi`, `django` ให้ plugin `reusable-dev` โดยใช้ workflow, กฎ C1–C8/F1–F8, report format และ extension points เดิมทั้งหมด

### Phase 2 ทั้งหมด (แบ่งตามความยาก toolchain)
| รอบ | Stacks | สถานะ |
|---|---|---|
| **2a** | `nestjs`, `fastapi`, `django` | spec นี้ |
| 2b | `laravel`, `rust-axum`, `swiftui` | spec แยกภายหลัง |
| 2c | `dotnet` (ASP.NET Core API + Blazor ในไฟล์เดียว) | spec แยกภายหลัง |

### Non-goals (2a)
- ไม่เพิ่ม shadcn port อื่น
- ไม่ติดตั้ง `@nestjs/*`, `fastapi`, `django` หรือ package อื่นในเครื่อง; fixture ต้องรันได้ด้วย `node` และ `python3` ที่มีอยู่ ไม่ใช้เน็ต
- ไม่เปลี่ยน workflow 6 ขั้น, report prefixes, tiers T1–T4, extension points

## 2. โครงสร้างไฟล์ reference

แนวทาง **framework file อ้าง language core** (pattern เดียวกับ `ui-libs/shadcn-core.md`)

```
skills/reusable-dev/references/stacks/
├── node-ts.md        (มีอยู่แล้ว — core ของ Node)
├── nestjs.md         ← บรรทัดหลัง research comment: "Read node-ts.md first."
├── python-core.md    ← ใหม่: ใช้ร่วมทุก Python stack; ใช้เดี่ยวเมื่อ stack = python
├── fastapi.md        ← "Read python-core.md first."
└── django.md         ← "Read python-core.md first."
```

ทุกไฟล์ใช้ section ตาม `stacks/_template.md`, ≤ 150 บรรทัด, ภาษาอังกฤษ, บรรทัดแรก `<!-- researched 2026-09-15: <lib>@<version>, … -->` จากเอกสารทางการ (nestjs.com, fastapi.tiangolo.com, docs.djangoproject.com, docs.python.org)

## 3. แก้ของเดิม

### 3.1 Detection ใน `references/config-format.md`
ตารางมีกฎ **ใช้แถวแรกที่ตรง (บนลงล่าง)**:

| ลำดับ | Signal | Value |
|---|---|---|
| 1 | `next.config.*` / `"next"` | `react-next` |
| 2 | `nuxt.config.*` / `"nuxt"` / `"vue"` | `vue-nuxt` |
| 3 | `svelte.config.*` / `"@sveltejs/kit"` | `sveltekit` |
| 4 | `"react"` without next | `react-next` |
| 5 | `"@nestjs/core"` in deps or `nest-cli.json` | `nestjs` |
| 6 | package.json with another server framework (`express`, `fastify`, `hono`) or no UI framework | `node-ts` |
| 7 | `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` | `django` |
| 8 | `fastapi` in `pyproject.toml` / `requirements*.txt` | `fastapi` |
| 9 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `python` |

แถว ui_lib, commands, monorepo path map คงเดิม

**`commands.test` ของ Python:** `pytest` ใน deps → `pytest` · มี `manage.py` → `python manage.py test` · อื่นๆ → `python3 -m unittest`

**ค่า `stack` ที่ถูกต้อง** (บรรทัดอธิบาย config): เพิ่ม `nestjs|fastapi|django|python`

### 3.2 หัวข้อใหม่ "Source roots by language" ใน `config-format.md`
| ภาษา | Roots ที่ Discover ค้น | ข้าม |
|---|---|---|
| JS/TS | `src/`, `app/`, `lib/`, `components/`, `composables/`, `hooks/`, `utils/`, `stores/`, `server/`, `shared/`, `apps/*`, `packages/*` | `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `.svelte-kit` |
| Python | `src/`, `app/`, ทุก package ที่ root ที่มี `__init__.py` หรือ `apps.py` | `.venv`, `venv`, `__pycache__`, `migrations/`, `.pytest_cache`, `.mypy_cache` |

Shared paths เริ่มต้นฝั่ง Python (ใช้ตัวแรกที่มีอยู่): `common/`, `core/`, `shared/`, `app/shared/`, `src/<pkg>/shared/`

### 3.3 `SKILL.md` ขั้น Discover ข้อ 3
แทนรายการโฟลเดอร์ด้วย: `Grep \`shared_paths\` and the source roots for the project's language (\`references/config-format.md\` → "Source roots by language") for the same terms and for similar function bodies or prop names. Duplicates inside feature folders count.`

### 3.4 README
บรรทัด Stacks เพิ่ม `NestJS · FastAPI · Django`

## 4. เนื้อหา references

### `python-core.md`
- Reuse units: domain module (`pricing.py`), service class, `typing.Protocol` interfaces
- Logic idioms: F2 constructor/parameter injection typed by `Protocol`; F6 `throw` = domain exception classes, `result` = `Ok`/`Err` dataclasses; F7 type hints on public functions
- Testing: `python3 -m unittest path.to.test_module` / `pytest path/to/test_x.py`
- Component idioms: Not applicable — no UI
- Anti-patterns: catch-all `utils.py`; mutable module-level state; import-time side effects; `except Exception: pass`

### `fastapi.md`
- Paths: `app/routers/` → `app/services/` → `app/domain/`; `app/schemas/` for Pydantic
- Logic idioms: F2 via `Depends()` providers; thin routers
- Component idioms: Not applicable — no UI
- Testing: pure services with unittest/pytest; routes with `TestClient`
- Anti-patterns: business logic in path operations; module-level DB session; Pydantic schemas used as domain models everywhere

### `django.md`
- Reuse units: reusable apps, per-app `services.py`/`selectors.py`, custom `Manager`/`QuerySet`, `{% include %}` and inclusion tags
- Component idioms (C3–C6): inclusion tag with a `variant` argument; `{% include "x.html" with … only %}`; shared templates in `core/` or `common/`
- Logic idioms: business logic in `services.py`, not views/`save()`; reusable queries as `QuerySet` methods
- Testing: `python manage.py test app.tests.test_x`
- Anti-patterns: fat views; business logic in signals; feature apps importing each other; copy-and-tweak templates

### `nestjs.md`
- Reuse units: shareable `@Module` with `exports`, providers, custom decorators, pipes/guards/interceptors
- Paths: `src/<feature>/`; `src/common/` or `libs/` (Nest monorepo)
- Logic idioms: constructor injection with `@Injectable`; injection tokens for interfaces; pure domain functions without decorators
- Testing: `Test.createTestingModule` for providers; pure functions with `jest <path>` / `node --test <path>`
- Component idioms: Not applicable — no UI
- Anti-patterns: logic in controllers; circular module imports (`forwardRef` as a smell); global modules exporting everything; unnecessary request-scoped providers

## 5. Fixtures (`evals/fixtures/`)

ทุกตัว: `.claude/reusable-dev.md` (ครบทุก key, `commands.test` รันได้จริง) และ `docs/reuse-registry.md`; helper จัดรูปเงินเขียนซ้ำใน 2 feature; feature ที่ 3 (`customers`) ยังไม่ใช้

| Fixture | Signals | Duplicate helper | `commands.test` |
|---|---|---|---|
| `nestjs` | `package.json` with `@nestjs/core`, `nest-cli.json`; decorated `*.service.ts` + pure `*-pricing.ts` | `formatMoney` in `src/orders/order-pricing.ts` and `src/invoices/invoice-pricing.ts` | `node --test` (pure `*.test.ts` only) |
| `fastapi` | `pyproject.toml` with `fastapi`; `app/routers/`, `app/services/` (no fastapi import) | `format_money` in `app/services/orders.py` and `app/services/invoices.py` | `python3 -m unittest discover -s tests -t .` |
| `django` | `manage.py`; apps `orders/`, `invoices/`, `customers/` with `apps.py`; `services.py` plain Python | `format_money` in `orders/services.py` and `invoices/services.py` | `python3 -m unittest discover` |

Test ของ Python fixture ห้าม import `fastapi`/`django`

## 6. Evals

### 6.1 `14-rule-of-three-{nestjs,fastapi,django}`
- Prompt: "Show each customer's outstanding balance formatted like the orders and invoices pages." (ปรับคำตาม domain ของ fixture)
- Graders:
  - shared file created (`files` regex): nestjs `src/common/`; fastapi `app/(shared|domain)/`; django `(common|core)/`
  - both original files no longer define the helper (`not_contains`)
  - customers file imports from the shared location
  - tests green in trace: nestjs `(#|ℹ) fail 0`; python `Ran \d+ tests?[\s\S]*\bOK\b`
  - `Reuse decision:\s*Create` in last message
  - `skill-fired` (display only)

### 6.2 `15-setup-detects-{nestjs,fastapi,django}`
- Setup: fixture with `--no-config`; prompt `/reusable-dev:reuse-setup  (non-interactive: accept all detected defaults, leave unknown extension points empty)`
- Graders (pattern of case 11): Write attempted to `reusable-dev\.md`; Write input matches `stack:\s*<stack>`; Write input matches the expected `commands.test`; `no-bash-config-workaround` (Bash input_match `reusable-dev\.md`, min 0 max 0)

### 6.3 Regression
Cases `01`, `02`, `03`, `04`, `10`, `11`, 1 run each, with-plugin must stay 1.00.

### 6.4 Running
Only via `evals/lib/run-eval.sh`, one case or small group at a time (Docker Desktop stays running; keep each run short).

## 7. Error handling
- Stack detected but reference file missing → existing rule (general rules + Notes)
- `python` (no framework) → load `python-core.md` only
- Django + FastAPI in one project → `django` (row order)
- Python command signals missing → `commands.test` = `python3 -m unittest`, reported as run or `skipped`

## 8. Acceptance
- `claude plugin validate . --strict` passes; references ≤ 150 lines; SKILL.md body ≤ 120 lines
- 6 new cases with-plugin 1.00 (1 run); regression cases with-plugin 1.00 (1 run)
- Always-on token cost does not grow (references load on demand only)
