# reusable-dev Phase 2a (NestJS, FastAPI, Django) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `nestjs`, `fastapi`, `django` stack support to the reusable-dev plugin, with language-aware detection and Discover roots, and eval evidence for each stack.

**Architecture:** Framework reference files point to a language core (`nestjs.md` → existing `node-ts.md`; `fastapi.md`/`django.md` → new `python.md`), the same pattern as `ui-libs/shadcn-core.md`. Detection and Discover source roots move into `references/config-format.md` so SKILL.md stays language-neutral. Each stack gets a runnable fixture and two eval cases (Rule of Three behavior, `/reuse-setup` detection).

**Tech Stack:** Claude Code plugin (Markdown), `claude plugin eval` via `evals/lib/run-eval.sh`, Node 26 `node --test` (TypeScript type stripping), Python 3.14 stdlib `unittest`.

**Spec:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2a-design.md`

## Global Constraints

- Do not install, uninstall, or upgrade software (no brew, npm, pip, composer). Fixtures run with the existing `node` and `python3` only; Python fixture tests must not import `fastapi` or `django`; NestJS tests must not import decorated files.
- Run evals only via `evals/lib/run-eval.sh` (it stashes `~/.docker`); one case or small group at a time; `--runs 1` unless stated. After each run: `ls -d ~/.docker` exists and `~/.docker.eval-stash` does not; otherwise run `evals/lib/run-eval.sh --restore` and stop.
- Never restart a stopped eval on your own.
- References ≤ 150 lines, English, section order of `stacks/_template.md`, first line `<!-- researched 2026-09-15: <lib>@<version>, … -->` from official docs; framework files have `Read <core>.md first.` as the next line.
- SKILL.md body ≤ 120 lines. Report prefixes `Reuse decision:` / `Verified:` / `Notes:`, ladder, tiers T1–T4, seven extension points unchanged.
- New `stack` values exactly: `nestjs`, `fastapi`, `django`, `python`.
- Eval grader rules learned in Phase 1: `tool_used` with `max: 0` also needs `min: 0`; `node --test` graders use `(#|ℹ) fail 0`; Python graders use `Ran (?:[3-9]|\d{2,}) tests? in [\d.]+s(?:\\n|\s)+OK\b` (≥3 tests: fixture has 2, the task adds one; trace stores output JSON-escaped) (trace stores output JSON-escaped); never put a fixture file/function name or grader string into shipped plugin files (`skills/`, `commands/`, `agents/`).
- Every setup.sh starts with `#!/bin/bash` and `set -euo pipefail`, is executable, and calls `"$(dirname "$0")/../lib/use-fixture.sh" <fixture> [--no-config]`.
- Commit after every task. Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
  ```

---

## File Structure

```
skills/reusable-dev/SKILL.md                               Task 1 (Discover step 3)
skills/reusable-dev/references/config-format.md            Task 1 (detection order, python commands, source roots)
README.md                                                  Task 1 (stacks line)
skills/reusable-dev/references/stacks/python.md       Task 2
skills/reusable-dev/references/stacks/fastapi.md           Task 2
skills/reusable-dev/references/stacks/django.md            Task 3
skills/reusable-dev/references/stacks/nestjs.md            Task 4
evals/fixtures/fastapi/**                                  Task 2
evals/fixtures/django/**                                   Task 3
evals/fixtures/nestjs/**                                   Task 4
evals/14-rule-of-three-{fastapi,django,nestjs}/            Tasks 2–4
evals/15-setup-detects-{fastapi,django,nestjs}/            Tasks 2–4
```

---

### Task 1: Language-aware detection and Discover roots

**Files:**
- Modify: `skills/reusable-dev/references/config-format.md`
- Modify: `skills/reusable-dev/SKILL.md` (Discover step 3 line)
- Modify: `README.md` (Stacks line)

**Interfaces:**
- Produces: config-format.md sections `## Detection signals` (ordered, first match wins) and `## Source roots by language`; `stack` values `nestjs|fastapi|django|python` used by Tasks 2–4 and cases 15-*.

- [ ] **Step 1: Replace the detection table in `config-format.md`**

Replace the whole table under `## Detection signals` with this text (keep the paragraph that follows the table):

```markdown
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
```

- [ ] **Step 2: Update the allowed `stack` values**

In `config-format.md`, replace the schema line

```
stack: react-next            # react-next | vue-nuxt | sveltekit | node-ts, or an ecosystem name (go | python | php, no reference file), or a path map for monorepos:
```

with

```
stack: react-next            # react-next | vue-nuxt | sveltekit | node-ts | nestjs | fastapi | django | python, or an ecosystem name (go | php, no reference file), or a path map for monorepos:
```

(`python` now has a reference: `stacks/python.md`. Also add one sentence after the detection table: `` `stack: python` loads `stacks/python.md`. ``)

- [ ] **Step 3: Add the source roots section**

Directly after the paragraph that follows the detection table (the one starting `A project stack file may live at`), add:

```markdown
## Source roots by language

| Language | Discover roots (whichever exist) | Skip |
|---|---|---|
| JS/TS | `src/`, `app/`, `lib/`, `components/`, `composables/`, `hooks/`, `utils/`, `stores/`, `server/`, `shared/`, `apps/*`, `packages/*` | `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `.svelte-kit` |
| Python | `src/`, `app/`, every root package with `__init__.py` or `apps.py` | `.venv`, `venv`, `__pycache__`, `migrations/`, `.pytest_cache`, `.mypy_cache` |

Python shared paths (first that exists): `common/`, `core/`, `shared/`, `app/shared/`, `src/<pkg>/shared/`.
```

And in the same paragraph that lists JS shared-path defaults, keep it unchanged.

- [ ] **Step 4: Update SKILL.md Discover step 3**

Replace the line starting `3. Grep \`shared_paths\` and the whole source tree` with:

```markdown
3. Grep `shared_paths` and the source roots for the project's language (`references/config-format.md` → "Source roots by language") for the same terms and for similar function bodies or prop names. Duplicates inside feature folders count.
```

- [ ] **Step 5: README stacks line**

Replace `Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript` with `Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript · NestJS · FastAPI · Django`.

- [ ] **Step 6: Validate**

Run: `claude plugin validate . --strict && wc -l skills/reusable-dev/SKILL.md skills/reusable-dev/references/config-format.md`
Expected: validation passed; SKILL.md ≤ 125 lines total; config-format.md ≤ 150.

- [ ] **Step 7: Regression evals**

Run one at a time:
```bash
evals/lib/run-eval.sh --runs 1 --case 01-extend-button-react
evals/lib/run-eval.sh --runs 1 --case 02-reuse-existing-function
evals/lib/run-eval.sh --runs 1 --case 03-pressure-urgent
evals/lib/run-eval.sh --runs 1 --case 04-rule-of-three
evals/lib/run-eval.sh --runs 1 --case 10-audit-reports-without-editing
evals/lib/run-eval.sh --runs 1 --case 11-setup-writes-config
```
Expected: with-plugin 1.00 for each. On a failure, rerun that case with `--keep-temp`, read `<kept>/out/trace.jsonl` read-only, and fix only the wording changed in this task.

- [ ] **Step 8: Commit**

```bash
git add skills/reusable-dev/SKILL.md skills/reusable-dev/references/config-format.md README.md
git commit -m "feat: ordered stack detection and language-aware discover roots"
```

---

### Task 2: Python (language core) + FastAPI (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/python.md`, `skills/reusable-dev/references/stacks/fastapi.md`
- Create: `evals/fixtures/fastapi/**` (listed in Step 1)
- Create: `evals/14-rule-of-three-fastapi/{case.yaml,setup.sh}`, `evals/15-setup-detects-fastapi/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: detection row 8, Python commands rule, Python source roots (Task 1).
- Produces: `python.md` (Task 3 `django.md` starts with `Read python.md first.`).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/fastapi/pyproject.toml`
```toml
[project]
name = "fixture-fastapi"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["fastapi>=0.115"]
```

Empty files: `evals/fixtures/fastapi/app/__init__.py`, `app/services/__init__.py`, `app/routers/__init__.py`, `tests/__init__.py`.

`evals/fixtures/fastapi/app/services/orders.py`
```python
def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def order_total_label(lines: list[tuple[int, int]]) -> str:
    total = sum(cents * qty for cents, qty in lines)
    return f"Order total: {format_money(total)}"
```

`evals/fixtures/fastapi/app/services/invoices.py`
```python
def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def amount_due_label(amounts: list[int]) -> str:
    return f"Amount due: {format_money(sum(amounts))}"
```

`evals/fixtures/fastapi/app/services/customers.py`
```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Customer:
    id: str
    name: str
    balance_cents: int
```

`evals/fixtures/fastapi/app/routers/orders.py`
```python
from fastapi import APIRouter

from app.services.orders import order_total_label

router = APIRouter()


@router.post("/orders/label")
def label(lines: list[tuple[int, int]]) -> dict[str, str]:
    return {"label": order_total_label(lines)}
```

`evals/fixtures/fastapi/tests/test_orders.py`
```python
import unittest

from app.services.orders import order_total_label


class OrderTotalLabelTest(unittest.TestCase):
    def test_sums_lines(self) -> None:
        self.assertEqual(order_total_label([(1000, 2), (500, 1)]), "Order total: $25.00")
```

`evals/fixtures/fastapi/tests/test_invoices.py`
```python
import unittest

from app.services.invoices import amount_due_label


class AmountDueLabelTest(unittest.TestCase):
    def test_sums_amounts(self) -> None:
        self.assertEqual(amount_due_label([100, 250]), "Amount due: $3.50")
```

`evals/fixtures/fastapi/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| order_total_label | app/services/orders.py | Label an order total | `(lines)` | 1 | pure |
| amount_due_label | app/services/invoices.py | Label an invoice amount due | `(amounts)` | 0 | pure |
```

`evals/fixtures/fastapi/.claude/reusable-dev.md`
```markdown
---
stack: fastapi
ui_lib: ""
shared_paths:
  components: ""
  functions: app/shared
commands:
  typecheck: ""
  lint: ""
  test: "python3 -m unittest discover -s tests -t ."
  build: ""
  e2e: ""
error_style: throw
registry: docs/reuse-registry.md
skills:
  design: []
  test: []
  verify: []
  debug: []
  review: []
  plan: []
  e2e: []
---
Fixture project for reusable-dev evals.
```

- [ ] **Step 2: Check the fixture tests run**

Run: `cd evals/fixtures/fastapi && python3 -m unittest discover -s tests -t . ; cd -`
Expected: `Ran 2 tests` and `OK`.

- [ ] **Step 3: Write both eval cases (RED)**

`evals/14-rule-of-three-fastapi/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" fastapi
```

`evals/14-rule-of-three-fastapi/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-fastapi
description: FastAPI — a third money-formatting need extracts the duplicated helper to shared and keeps tests green.
tags: [phase2a, fastapi]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a balance_label(customer) function in app/services/customers.py that returns text like \"Balance: $12.50\" from customer.balance_cents, with a unittest test in tests/test_customers.py."
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: "app/(shared|domain)/[^\\n]*\\.py"
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: app/services/orders.py }
    pattern: "def format_money"
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: app/services/invoices.py }
    pattern: "def format_money"
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: app/services/customers.py }
    pattern: "from app\\.(shared|domain)[\\w.]* import"
  - type: regex
    name: tests-green
    target: trace
    pattern: "Ran (?:[3-9]|\\d{2,}) tests? in [\\d.]+s(?:\\\\n|\\s)+OK\\b"
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: tests/test_orders.py }
    pattern: "Order total: \\$25\\.00"
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: tests/test_invoices.py }
    pattern: "Amount due: \\$3\\.50"
  - type: regex
    name: reports-create
    pattern: "Reuse decision:\\s*Create"
    flags: i
  - type: tool_used
    name: skill-fired
    tool: Skill
    input_match: "reusable-dev"
```

`evals/15-setup-detects-fastapi/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" fastapi --no-config
```

`evals/15-setup-detects-fastapi/case.yaml`
```yaml
schema_version: "1.0"
name: 15-setup-detects-fastapi
description: /reuse-setup detects the FastAPI stack and unittest command (graded on the write attempt; the eval sandbox denies .claude/** writes).
tags: [phase2a, fastapi]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-setup  (non-interactive: accept all detected defaults, leave unknown extension points empty)"
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Bash, Write, Edit]
graders:
  - type: tool_used
    name: attempted-config-write
    tool: Write
    input_match: "reusable-dev\\.md"
    min: 1
  - type: tool_used
    name: config-has-fastapi
    tool: Write
    input_match: "stack:\\s*fastapi"
    min: 1
  - type: tool_used
    name: config-has-unittest-command
    tool: Write
    input_match: "test:\\s*\\\\?\"?python3 -m unittest"
    min: 1
  - type: tool_used
    name: no-bash-config-workaround
    tool: Bash
    input_match: "reusable-dev\\.md"
    min: 0
    max: 0
```

`chmod +x` both setup.sh files.

Run: `evals/lib/run-eval.sh --runs 1 --case "14-rule-of-three-fastapi"` then `evals/lib/run-eval.sh --runs 1 --case "15-setup-detects-fastapi"`
Record both tables (RED: references not written yet; case 15 may already pass from Task 1 detection — record either way).

- [ ] **Step 4: Research and write `python.md`**

Sources: docs.python.org (unittest, typing.Protocol, dataclasses), pytest docs. Content (fill every `_template.md` section):
- Detection: `pyproject.toml` / `requirements*.txt` / `setup.py` without Django/FastAPI.
- Reuse units: domain modules named by domain (`pricing.py`, `dates.py`), service classes, `typing.Protocol` interfaces.
- Paths: `src/<pkg>/` or root packages; shared code in `common/`, `core/`, `shared/`.
- Component idioms: `Not applicable — no UI`.
- Logic idioms: F2 constructor/parameter injection typed with `Protocol` (short example); F6 `throw` = domain exception classes, `result` = `Ok`/`Err` dataclasses (short example); F7 type hints on public functions.
- Testing: `python3 -m unittest path.to.test_module`; `pytest path/to/test_x.py`; tests next to code or in `tests/` mirroring packages.
- Anti-patterns: catch-all `utils.py`; mutable module-level state; import-time side effects; `except Exception: pass`.

- [ ] **Step 5: Research and write `fastapi.md`**

Sources: fastapi.tiangolo.com (Dependencies, Bigger Applications, Testing). First lines: research comment, then `Read python.md first.`. Content:
- Detection: `fastapi` in `pyproject.toml` / `requirements*.txt`.
- Reuse units: service functions/classes, dependency providers, Pydantic schemas (boundary only).
- Paths: `app/routers/` (adapters) → `app/services/` → `app/domain/`; shared helpers in `app/shared/`; `app/schemas/`.
- Component idioms: `Not applicable — no UI`.
- Logic idioms: F2 via `Depends()` providers (short example: router receives service via `Depends(get_order_service)`); thin routers.
- Testing: pure services with unittest/pytest; routes with `fastapi.testclient.TestClient`; single-file commands.
- Anti-patterns: business logic in path operations; module-level DB session/engine side effects; Pydantic schemas used as domain models in every layer.

- [ ] **Step 6: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/python.md skills/reusable-dev/references/stacks/fastapi.md && claude plugin validate . --strict`
Run: `evals/lib/run-eval.sh --runs 1 --case "14-rule-of-three-fastapi"` then `evals/lib/run-eval.sh --runs 1 --case "15-setup-detects-fastapi"`
Expected: with-plugin 1.00 for both. On failure: rerun with `--keep-temp`, read the trace, tighten the reference wording (not graders unless provably wrong, with quoted evidence). Max 2 reruns per case.

- [ ] **Step 7: Commit**

```bash
git add skills/reusable-dev/references/stacks/python.md skills/reusable-dev/references/stacks/fastapi.md evals/fixtures/fastapi evals/14-rule-of-three-fastapi evals/15-setup-detects-fastapi
git commit -m "feat: add python and fastapi stack references with evals"
```

---

### Task 3: Django (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/django.md`
- Create: `evals/fixtures/django/**`
- Create: `evals/14-rule-of-three-django/{case.yaml,setup.sh}`, `evals/15-setup-detects-django/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: `python.md` (Task 2), detection row 7 (Task 1).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/django/requirements.txt`
```
Django>=5.1
```

`evals/fixtures/django/manage.py`
```python
#!/usr/bin/env python
import os
import sys


def main() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
```

Empty files: `evals/fixtures/django/config/__init__.py`, `orders/__init__.py`, `invoices/__init__.py`, `customers/__init__.py`.

`evals/fixtures/django/config/settings.py`
```python
SECRET_KEY = "fixture-only"
INSTALLED_APPS = ["orders", "invoices", "customers"]
```

`evals/fixtures/django/orders/apps.py`
```python
from django.apps import AppConfig


class OrdersConfig(AppConfig):
    name = "orders"
```

`evals/fixtures/django/invoices/apps.py`
```python
from django.apps import AppConfig


class InvoicesConfig(AppConfig):
    name = "invoices"
```

`evals/fixtures/django/customers/apps.py`
```python
from django.apps import AppConfig


class CustomersConfig(AppConfig):
    name = "customers"
```

`evals/fixtures/django/orders/services.py`
```python
def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def order_total_label(lines: list[tuple[int, int]]) -> str:
    total = sum(cents * qty for cents, qty in lines)
    return f"Order total: {format_money(total)}"
```

`evals/fixtures/django/invoices/services.py`
```python
def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def amount_due_label(amounts: list[int]) -> str:
    return f"Amount due: {format_money(sum(amounts))}"
```

`evals/fixtures/django/customers/services.py`
```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Customer:
    id: str
    name: str
    balance_cents: int
```

`evals/fixtures/django/orders/tests.py`
```python
import unittest

from orders.services import order_total_label


class OrderTotalLabelTest(unittest.TestCase):
    def test_sums_lines(self) -> None:
        self.assertEqual(order_total_label([(1000, 2), (500, 1)]), "Order total: $25.00")
```

`evals/fixtures/django/invoices/tests.py`
```python
import unittest

from invoices.services import amount_due_label


class AmountDueLabelTest(unittest.TestCase):
    def test_sums_amounts(self) -> None:
        self.assertEqual(amount_due_label([100, 250]), "Amount due: $3.50")
```

`evals/fixtures/django/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| order_total_label | orders/services.py | Label an order total | `(lines)` | 0 | pure |
| amount_due_label | invoices/services.py | Label an invoice amount due | `(amounts)` | 0 | pure |
```

`evals/fixtures/django/.claude/reusable-dev.md` — same as the FastAPI fixture config except:
```yaml
stack: django
shared_paths:
  components: common/templates
  functions: common
commands:
  test: "python3 -m unittest discover"
```
(write the full file with every key, following the FastAPI fixture config layout, with body text `Fixture project for reusable-dev evals. Django is not installed; tests cover plain-Python services only.`)

- [ ] **Step 2: Check the fixture tests run**

Run: `cd evals/fixtures/django && python3 -m unittest discover ; cd -`
Expected: `Ran 2 tests` and `OK`.

- [ ] **Step 3: Write both eval cases (RED)**

`evals/14-rule-of-three-django/setup.sh` — the 3-line template with fixture `django`.

`evals/14-rule-of-three-django/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-django
description: Django — a third money-formatting need extracts the duplicated helper to a shared app module and keeps tests green.
tags: [phase2a, django]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a balance_label(customer) function in customers/services.py that returns text like \"Balance: $12.50\" from customer.balance_cents, with a unittest test in customers/tests.py."
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: "(^|\\n)(common|core)/[^\\n]*\\.py"
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: orders/services.py }
    pattern: "def format_money"
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: invoices/services.py }
    pattern: "def format_money"
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: customers/services.py }
    pattern: "from (common|core)[\\w.]* import"
  - type: regex
    name: tests-green
    target: trace
    pattern: "Ran (?:[3-9]|\\d{2,}) tests? in [\\d.]+s(?:\\\\n|\\s)+OK\\b"
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: orders/tests.py }
    pattern: "Order total: \\$25\\.00"
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: invoices/tests.py }
    pattern: "Amount due: \\$3\\.50"
  - type: regex
    name: reports-create
    pattern: "Reuse decision:\\s*Create"
    flags: i
  - type: tool_used
    name: skill-fired
    tool: Skill
    input_match: "reusable-dev"
```

`evals/15-setup-detects-django/setup.sh` — the 3-line template with `django --no-config`.

`evals/15-setup-detects-django/case.yaml` — identical to `15-setup-detects-fastapi/case.yaml` except: `name: 15-setup-detects-django`, `description` says Django, `tags: [phase2a, django]`, grader `config-has-fastapi` becomes:
```yaml
  - type: tool_used
    name: config-has-django
    tool: Write
    input_match: "stack:\\s*django"
    min: 1
```
and grader `config-has-unittest-command` becomes:
```yaml
  - type: tool_used
    name: config-has-django-test-command
    tool: Write
    input_match: "test:\\s*\\\\?\"?python3? manage\\.py test"
    min: 1
```
(Write the full file.)

`chmod +x` both setup.sh. Run both cases once (RED) and record.

- [ ] **Step 4: Research and write `django.md`**

Sources: docs.djangoproject.com (applications, managers/QuerySet, custom template tags → inclusion tags, `include` tag, testing). First lines: research comment, then `Read python.md first.`. Content:
- Detection: `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt`.
- Reuse units: reusable apps; per-app `services.py` / `selectors.py`; custom `Manager` / `QuerySet` methods; `{% include %}` partials and inclusion tags.
- Paths: feature apps at root; shared logic in a `common/` or `core/` app (with `__init__.py`); shared templates in `common/templates/common/`; skip `migrations/`.
- Component idioms (C3–C6): inclusion tag taking a `variant` argument (short example); `{% include "common/button.html" with variant="danger" only %}`; no copy-and-tweak templates.
- Logic idioms: business logic in `services.py`, not views, signals, or `Model.save()`; reusable queries as `QuerySet` methods; F2 pass collaborators into service functions.
- Testing: `python manage.py test app.tests.test_x`; plain-Python services testable with `unittest` without Django settings.
- Anti-patterns: fat views; business logic in signals; feature apps importing each other's internals; copy-and-tweak templates.

- [ ] **Step 5: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/django.md && claude plugin validate . --strict`
Run both django cases once each. Expected with-plugin 1.00. Same failure handling as Task 2 Step 6.

Note for case 15-django: the fixture has `manage.py` and no pytest, so the detected command is `python manage.py test`; the grader accepts `python` or `python3`.

- [ ] **Step 6: Commit**

```bash
git add skills/reusable-dev/references/stacks/django.md evals/fixtures/django evals/14-rule-of-three-django evals/15-setup-detects-django
git commit -m "feat: add django stack reference with evals"
```

---

### Task 4: NestJS (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/nestjs.md`
- Create: `evals/fixtures/nestjs/**`
- Create: `evals/14-rule-of-three-nestjs/{case.yaml,setup.sh}`, `evals/15-setup-detects-nestjs/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: existing `stacks/node-ts.md`, detection row 5 (Task 1).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/nestjs/package.json`
```json
{
  "name": "fixture-nestjs",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" },
  "dependencies": { "@nestjs/common": "^11.0.0", "@nestjs/core": "^11.0.0" }
}
```

`evals/fixtures/nestjs/nest-cli.json`
```json
{ "collection": "@nestjs/schematics", "sourceRoot": "src" }
```

`evals/fixtures/nestjs/src/orders/order-pricing.ts`
```ts
function formatMoney(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function orderTotalLabel(lines: { cents: number; qty: number }[]): string {
  const total = lines.reduce((sum, line) => sum + line.cents * line.qty, 0);
  return `Order total: ${formatMoney(total)}`;
}
```

`evals/fixtures/nestjs/src/orders/order-pricing.test.ts`
```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { orderTotalLabel } from "./order-pricing.ts";

test("sums order lines", () => {
  assert.equal(orderTotalLabel([{ cents: 1000, qty: 2 }, { cents: 500, qty: 1 }]), "Order total: $25.00");
});
```

`evals/fixtures/nestjs/src/orders/orders.service.ts`
```ts
import { Injectable } from "@nestjs/common";
import { orderTotalLabel } from "./order-pricing.ts";

@Injectable()
export class OrdersService {
  label(lines: { cents: number; qty: number }[]): string {
    return orderTotalLabel(lines);
  }
}
```

`evals/fixtures/nestjs/src/invoices/invoice-pricing.ts`
```ts
function formatMoney(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function amountDueLabel(amountsCents: number[]): string {
  return `Amount due: ${formatMoney(amountsCents.reduce((sum, cents) => sum + cents, 0))}`;
}
```

`evals/fixtures/nestjs/src/invoices/invoice-pricing.test.ts`
```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { amountDueLabel } from "./invoice-pricing.ts";

test("sums invoice amounts", () => {
  assert.equal(amountDueLabel([100, 250]), "Amount due: $3.50");
});
```

`evals/fixtures/nestjs/src/customers/customers.service.ts`
```ts
import { Injectable } from "@nestjs/common";

export type Customer = { id: string; name: string; balanceCents: number };

@Injectable()
export class CustomersService {
  findAll(): Customer[] {
    return [{ id: "c1", name: "Ada", balanceCents: 1250 }];
  }
}
```

`evals/fixtures/nestjs/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| orderTotalLabel | src/orders/order-pricing.ts | Label an order total | `(lines)` | 1 | pure |
| amountDueLabel | src/invoices/invoice-pricing.ts | Label an invoice amount due | `(amountsCents)` | 0 | pure |
```

`evals/fixtures/nestjs/.claude/reusable-dev.md` — full config with `stack: nestjs`, `ui_lib: ""`, `shared_paths.components: ""`, `shared_paths.functions: src/common`, `commands.test: "node --test"`, other commands `""`, `error_style: throw`, `registry: docs/reuse-registry.md`, all seven `skills` points `[]`, body `Fixture project for reusable-dev evals. Nest packages are not installed; tests cover pure functions only.`

- [ ] **Step 2: Check the fixture tests run**

Run: `cd evals/fixtures/nestjs && node --test ; cd -`
Expected: `pass 2`, `fail 0` (decorated files are not imported by tests).

- [ ] **Step 3: Write both eval cases (RED)**

`evals/14-rule-of-three-nestjs/setup.sh` — 3-line template with fixture `nestjs`.

`evals/14-rule-of-three-nestjs/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-nestjs
description: NestJS — a third money-formatting need extracts the duplicated helper to src/common and keeps tests green.
tags: [phase2a, nestjs]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a balanceLabel(customer) function in src/customers/customer-balance.ts that returns text like \"Balance: $12.50\" from customer.balanceCents, with a node:test test in src/customers/customer-balance.test.ts."
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: "src/(common|shared)/[^\\n]*\\.ts"
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: src/orders/order-pricing.ts }
    pattern: "function formatMoney"
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: src/invoices/invoice-pricing.ts }
    pattern: "function formatMoney"
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: src/customers/customer-balance.ts }
    pattern: "from\\s+[\"'][^\"']*(common|shared)/"
  - type: regex
    name: tests-green
    target: trace
    pattern: "(#|ℹ) fail 0"
  - type: regex
    name: new-test-counted
    target: trace
    pattern: "(#|ℹ) pass (?:[3-9]|\\d{2,})"
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: src/orders/order-pricing.test.ts }
    pattern: "Order total: \\$25\\.00"
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: src/invoices/invoice-pricing.test.ts }
    pattern: "Amount due: \\$3\\.50"
  - type: regex
    name: reports-create
    pattern: "Reuse decision:\\s*Create"
    flags: i
  - type: tool_used
    name: skill-fired
    tool: Skill
    input_match: "reusable-dev"
```

`evals/15-setup-detects-nestjs/setup.sh` — 3-line template with `nestjs --no-config`.

`evals/15-setup-detects-nestjs/case.yaml` — identical layout to the FastAPI detect case with `name: 15-setup-detects-nestjs`, `tags: [phase2a, nestjs]`, and these two graders instead of the fastapi/unittest ones:
```yaml
  - type: tool_used
    name: config-has-nestjs
    tool: Write
    input_match: "stack:\\s*nestjs"
    min: 1
  - type: tool_used
    name: config-has-npm-test-command
    tool: Write
    input_match: "test:\\s*\\\\?\"?(npm|pnpm|yarn|bun) (run )?test"
    min: 1
```
(Write the full file.)

`chmod +x` both setup.sh. Before running, verify the `imports-shared` regex with node against the string `import { formatMoney } from \"../common/money.ts\";` (as it appears JSON-escaped in a trace) and `import { formatMoney } from "../common/money.ts";` — both must match; adjust only the quoting part if not, and record the node output. Run both cases once (RED) and record.

- [ ] **Step 4: Research and write `nestjs.md`**

Sources: docs.nestjs.com (modules → shared modules, providers, custom providers/injection tokens, testing, monorepo libraries). First lines: research comment, then `Read node-ts.md first.`. Content:
- Detection: `@nestjs/core` in deps or `nest-cli.json`.
- Reuse units: shareable `@Module` with `exports`; providers; custom decorators; pipes/guards/interceptors; pure domain functions.
- Paths: `src/<feature>/` (module, controller, service); `src/common/` for shared helpers/providers; `libs/` in Nest monorepo mode.
- Component idioms: `Not applicable — no UI`.
- Logic idioms: constructor injection with `@Injectable`; injection tokens (`@Inject(TOKEN)`) for interfaces (short example); keep domain logic in plain functions without decorators so it is testable without Nest.
- Testing: `Test.createTestingModule` for providers; pure functions with the project's runner (`jest <path>`, `vitest run <path>`, or `node --test <path>`).
- Anti-patterns: logic in controllers; circular module imports (`forwardRef` as a smell); a global module exporting everything; unnecessary request-scoped providers.

- [ ] **Step 5: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/nestjs.md && claude plugin validate . --strict`
Run both nestjs cases once each. Expected with-plugin 1.00. Same failure handling as Task 2 Step 6.

- [ ] **Step 6: Commit**

```bash
git add skills/reusable-dev/references/stacks/nestjs.md evals/fixtures/nestjs evals/14-rule-of-three-nestjs evals/15-setup-detects-nestjs
git commit -m "feat: add nestjs stack reference with evals"
```

---

### Task 5: Phase 2a acceptance

**Files:**
- Modify: `docs/superpowers/specs/2026-09-15-reusable-dev-phase2a-design.md` (status line only)

- [ ] **Step 1: Structural checks**

Run:
```bash
claude plugin validate . --strict
wc -l skills/reusable-dev/SKILL.md skills/reusable-dev/references/*.md skills/reusable-dev/references/stacks/*.md
claude --plugin-dir . plugin details reusable-dev | sed -n '/Projected token cost/,/Per-component/p'
grep -rn "format_money\|formatMoney\|order_total_label\|orderTotalLabel\|amount_due_label\|amountDueLabel" skills commands agents
```
Expected: validation passed; limits hold; always-on cost ≈ 761 tokens (unchanged from phase 1); the grep prints nothing (no fixture names in shipped files).

- [ ] **Step 2: Tag check of new cases**

Run: `evals/lib/run-eval.sh --runs 1 --tag phase2a`
Expected: with-plugin 1.00 for all six cases. If the run takes longer than ~15 minutes or reports sandbox `credential store` errors, stop, run `evals/lib/run-eval.sh --restore` if a stash remains, and rerun the affected cases individually.

- [ ] **Step 3: Mark the spec implemented and commit**

In the spec, change `- **สถานะ:** Approved design, รอรีวิว spec` to `- **สถานะ:** Implemented (phase 2a)`.

```bash
git add docs/superpowers/specs/2026-09-15-reusable-dev-phase2a-design.md
git commit -m "docs: mark phase 2a spec implemented"
```
