# reusable-dev Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build phase 1 of the `reusable-dev` Claude Code plugin: an auto-triggering skill that makes Claude discover → decide → design → verify → register reusable components and functions, plus 4 slash commands, 1 read-only agent, stack/ui-lib references, and an eval suite that proves the behavior.

**Architecture:** The repo root is the plugin. One skill (`skills/reusable-dev/SKILL.md`) owns the workflow and loads focused files from `references/` on demand (progressive disclosure). Commands handle heavy, user-triggered work; `duplicate-finder` keeps repo scans out of the main context. Behavior is tested with `claude plugin eval` against small fixture projects; the built-in with/without ablation gives RED (no plugin) and GREEN (plugin) in one run.

**Tech Stack:** Claude Code plugin format (Markdown + YAML frontmatter, `plugin.json`), `claude plugin eval` / `claude plugin validate` (Claude Code 2.1.270), Node ≥ 22.18 (`node --test` with native TypeScript type stripping) for the `node-ts` fixture, Bash scaffold scripts.

**Spec:** `docs/superpowers/specs/2026-09-14-reusable-dev-plugin-design.md`

## Global Constraints

- Plugin name: `reusable-dev`. Skill name: `reusable-dev`. Commands are invoked as `/reusable-dev:reuse-setup`, `/reusable-dev:reuse-audit`, `/reusable-dev:reuse-registry`, `/reusable-dev:reuse-verify`.
- Plugin must not require any other plugin. Other skills are referenced only as optional examples in `references/integration.md`.
- Plugin content files (SKILL.md, references, commands, agent) are written in English; the skill `description` also contains Thai trigger phrases. README is Thai + English.
- `references/*.md` files: ≤ 150 lines each. `SKILL.md` body: ≤ 120 lines.
- Config path in target projects: `.claude/reusable-dev.md` (committed). Default registry path: `docs/reuse-registry.md`.
- Verification tiers are exactly: T1 typecheck·lint·build, T2 unit tests of touched units, T3 call-site tests for changed shared units, T4 e2e (`/reusable-dev:reuse-verify` only).
- Extension points are exactly: `design`, `test`, `verify`, `debug`, `review`, `plan`, `e2e`.
- Decision ladder is exactly: Reuse → Extend → Compose → Create, with Rule of Three for moving to shared.
- Eval suite lives in `evals/` (replaces the spec's `tests/` directory — Task 1 updates the spec). Fixtures live in `evals/fixtures/`.
- Standard eval command (run from repo root):
  `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish`
  RED/GREEN iteration may add `--runs 1 --case <name>`; final acceptance uses default 3 runs.
- Phase 1 stacks: `react-next`, `vue-nuxt`, `sveltekit`, `node-ts`. Phase 1 ui-libs: `shadcn-core`, `shadcn-react`, `shadcn-vue`, `shadcn-svelte`. Nothing else.
- Commit after every task. Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
  ```

## Verified tool facts (do not re-derive)

- `case.yaml` fields: `schema_version: "1.0"`, `name`, `description?`, `tags[]`, `plugins[]?`, `context: {scaffold_script?, history_file?, add_dirs[]}`, `execution: {prompt, max_turns (≤200, default 10), timeout_seconds (default 300), model?, allowed_tools[], append_system_prompt?, env{}}`, `runs` (default 3), `graders[]` (≥1, unique names), `expected_outcome?`.
- Grader types: `regex {name, target: last_message|trace|files|{source: file, path}, pattern, flags, match: contains|not_contains|count:N}`, `tool_used {name, tool, input_match?, min?, max?}`, `tool_order {name, before, after}`, `file_exists {name, path, exists}` (only counts files **created** during the run), `llm {name, criteria, focus}`, `baseline`.
- `scaffold_script` path is relative to the case directory; it runs with cwd = the eval workspace and `$0` = its absolute path. It runs only with `--scaffold`.
- Every case needs ≥ 1 outcome grader (not only `tool_used`); the suite needs ≥ 1 should-NOT-fire case.
- `plugins:` in a case can only point beneath the plugin root, so a case cannot load superpowers from the cache. Superpowers co-operation is checked manually (Task 12).

---

## File Structure

```
.claude-plugin/plugin.json                      Task 1
README.md                                       Task 1 (stub), Task 14 (full)
.gitignore                                      Task 1
skills/reusable-dev/SKILL.md                    Task 5
skills/reusable-dev/references/
  config-format.md                              Task 3
  registry-format.md                            Task 3
  component-design.md                           Task 4
  function-design.md                            Task 4
  verification.md                               Task 5
  integration.md                                Task 5
  stacks/_template.md, react-next.md,
    vue-nuxt.md, sveltekit.md, node-ts.md       Task 6
  ui-libs/_template.md, shadcn-core.md,
    shadcn-react.md, shadcn-vue.md,
    shadcn-svelte.md                            Task 7
agents/duplicate-finder.md                      Task 9
commands/reuse-audit.md                         Task 9
commands/reuse-setup.md                         Task 10
commands/reuse-registry.md                      Task 11
commands/reuse-verify.md                        Task 11
evals/lib/use-fixture.sh                        Task 2
evals/fixtures/node-ts/…                        Task 2
evals/fixtures/react-shadcn/…                   Task 2
evals/fixtures/vue-shadcn/…                     Task 7
evals/fixtures/svelte-shadcn/…                  Task 7
evals/<case>/case.yaml + setup.sh               Tasks 2, 5, 7, 8, 9, 10, 11
evals/MANUAL.md                                 Task 12
```

---

### Task 1: Plugin skeleton, validation, spec alignment

**Files:**
- Create: `.claude-plugin/plugin.json`, `README.md`, `.gitignore`
- Modify: `docs/superpowers/specs/2026-09-14-reusable-dev-plugin-design.md` (sections 2 and 12)

**Interfaces:**
- Produces: a plugin root that `claude plugin validate .` accepts; plugin name `reusable-dev`.

- [ ] **Step 1: Run validation on the empty repo to see it fail**

Run: `claude plugin validate .`
Expected: FAIL — no `.claude-plugin/plugin.json` found.

- [ ] **Step 2: Create `.claude-plugin/plugin.json`**

```json
{
  "name": "reusable-dev",
  "version": "0.1.0",
  "description": "Reuse-first development for full-stack apps: find existing components and functions before writing new ones, design them for reuse, keep a registry, and verify changes including call sites. Stack-agnostic with optional extension points for other skills.",
  "author": { "name": "ekayut" },
  "license": "MIT",
  "keywords": ["reuse", "components", "design-system", "shadcn", "refactor", "testing"]
}
```

- [ ] **Step 3: Create `.gitignore`**

```gitignore
.remember/
evals/results/
node_modules/
.DS_Store
```

- [ ] **Step 4: Create stub `README.md`**

```markdown
# reusable-dev

Claude Code plugin สำหรับพัฒนาระบบแบบ reuse-first — หา component/function เดิมก่อนสร้างใหม่ ออกแบบให้ reuse ได้ มีทะเบียน และตรวจสอบรวมถึงจุดที่เรียกใช้

Reuse-first development plugin for Claude Code. Full documentation lands in Task 14.
```

- [ ] **Step 5: Align the spec with the eval layout**

In `docs/superpowers/specs/2026-09-14-reusable-dev-plugin-design.md`:

Replace in section 2 the lines
```
├── tests/
│   ├── fixtures/                     ← react-shadcn, vue-shadcn, svelte-shadcn, node-ts
│   └── scenarios.md
```
with
```
├── evals/                            ← claude plugin eval suite
│   ├── fixtures/                     ← react-shadcn, vue-shadcn, svelte-shadcn, node-ts
│   ├── lib/use-fixture.sh
│   ├── <case>/case.yaml + setup.sh   ← หนึ่ง scenario ต่อหนึ่งโฟลเดอร์
│   └── MANUAL.md                     ← checklist ทดสอบมือ (ร่วมกับ superpowers)
```

Replace in section 12 the heading `### Fixtures (\`tests/fixtures/\`)` with `### Fixtures (\`evals/fixtures/\`)`, and `### Scenarios (\`tests/scenarios.md\`)` with `### Scenarios (\`evals/<case>/case.yaml\`)`. Replace the last bullet of section 12
```
- ประเมินว่าจะใช้ `claude plugin eval` รัน scenario อัตโนมัติได้หรือไม่ ตัดสินใจในขั้น implementation plan
```
with
```
- รัน scenario ด้วย `claude plugin eval` (ablation with-without = baseline ไม่มี plugin เทียบกับมี plugin)
- Scenario 6 (ร่วมกับ superpowers) ทดสอบด้วย eval ที่ไม่ต้องมี superpowers + checklist มือใน `evals/MANUAL.md` เพราะ eval โหลด plugin นอก root ไม่ได้
```

- [ ] **Step 6: Validate**

Run: `claude plugin validate .`
Expected: PASS (warnings about having no components are acceptable at this point; no errors).

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin/plugin.json README.md .gitignore docs/superpowers/specs/2026-09-14-reusable-dev-plugin-design.md
git commit -m "feat: scaffold reusable-dev plugin manifest"
```

---

### Task 2: Fixture helper, node-ts and react-shadcn fixtures, eval harness smoke test

**Files:**
- Create: `evals/lib/use-fixture.sh`
- Create: `evals/fixtures/node-ts/**` (listed below)
- Create: `evals/fixtures/react-shadcn/**` (listed below)
- Create: `evals/00-harness-smoke/case.yaml`, `evals/00-harness-smoke/setup.sh`

**Interfaces:**
- Produces: `evals/lib/use-fixture.sh <fixture-name> [--no-config]` — copies `evals/fixtures/<name>/.` into the cwd; `--no-config` deletes `.claude/reusable-dev.md` after copying. Every later `setup.sh` is exactly:
  ```bash
  #!/bin/bash
  set -euo pipefail
  exec "$(dirname "$0")/../lib/use-fixture.sh" <fixture-name> [--no-config]
  ```
- Produces fixture facts used by later graders:
  - node-ts: `src/shared/lib/money.ts` exports `formatCurrency(amount: number, currency: string): string`; call sites `src/features/orders/order-summary.ts`, `src/features/invoices/invoice-total.ts`; `npm test` = `node --test`, 3 test files, all passing.
  - react-shadcn: `src/components/ui/button.tsx` with cva variants `default | outline`; `src/shared/ui/DataTable.tsx`; duplicated `formatDate` in `src/features/orders/OrdersPage.tsx` and `src/features/invoices/InvoicesPage.tsx`; `src/shared/lib/format-date.ts` does NOT exist.

- [ ] **Step 1: Create `evals/lib/use-fixture.sh`**

```bash
#!/bin/bash
# Copy an eval fixture into the current eval workspace.
set -euo pipefail
name="${1:?fixture name required}"
src="$(cd "$(dirname "$0")/../fixtures/$name" && pwd)"
cp -R "$src/." .
if [[ "${2:-}" == "--no-config" ]]; then
  rm -f .claude/reusable-dev.md
fi
```

Run: `chmod +x evals/lib/use-fixture.sh`

- [ ] **Step 2: Create node-ts fixture files**

`evals/fixtures/node-ts/package.json`
```json
{
  "name": "fixture-node-ts",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
```

`evals/fixtures/node-ts/src/shared/lib/money.ts`
```ts
export function formatCurrency(amount: number, currency: string): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(amount);
}
```

`evals/fixtures/node-ts/src/shared/lib/money.test.ts`
```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { formatCurrency } from "./money.ts";

test("formats USD", () => {
  assert.equal(formatCurrency(1234.5, "USD"), "$1,234.50");
});
```

`evals/fixtures/node-ts/src/features/orders/order-summary.ts`
```ts
import { formatCurrency } from "../../shared/lib/money.ts";

export function orderSummary(items: { price: number; qty: number }[]): string {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return `Total: ${formatCurrency(total, "USD")}`;
}
```

`evals/fixtures/node-ts/src/features/orders/order-summary.test.ts`
```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { orderSummary } from "./order-summary.ts";

test("sums items", () => {
  assert.equal(orderSummary([{ price: 10, qty: 2 }, { price: 5, qty: 1 }]), "Total: $25.00");
});
```

`evals/fixtures/node-ts/src/features/invoices/invoice-total.ts`
```ts
import { formatCurrency } from "../../shared/lib/money.ts";

export function invoiceTotal(lines: number[], currency: string): string {
  return formatCurrency(lines.reduce((a, b) => a + b, 0), currency);
}
```

`evals/fixtures/node-ts/src/features/invoices/invoice-total.test.ts`
```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { invoiceTotal } from "./invoice-total.ts";

test("totals EUR lines", () => {
  assert.equal(invoiceTotal([1, 2.5], "EUR"), "€3.50");
});
```

`evals/fixtures/node-ts/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| formatCurrency | src/shared/lib/money.ts | Format a number as currency | `(amount, currency)` | 2 | pure |
```

`evals/fixtures/node-ts/.claude/reusable-dev.md`
```markdown
---
stack: node-ts
ui_lib: ""
shared_paths:
  components: ""
  functions: src/shared/lib
commands:
  typecheck: ""
  lint: ""
  test: "node --test"
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

- [ ] **Step 3: Run the node-ts fixture tests**

Run: `cd evals/fixtures/node-ts && node --test; cd -`
Expected: `# pass 3` and `# fail 0`.

- [ ] **Step 4: Create react-shadcn fixture files**

`evals/fixtures/react-shadcn/package.json`
```json
{
  "name": "fixture-react-shadcn",
  "private": true,
  "type": "module",
  "dependencies": {
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "react": "^19.1.0",
    "tailwind-merge": "^3.3.0"
  }
}
```

`evals/fixtures/react-shadcn/components.json`
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "tsx": true,
  "tailwind": { "css": "src/index.css", "baseColor": "neutral", "cssVariables": true },
  "aliases": { "components": "@/components", "ui": "@/components/ui", "utils": "@/lib/utils" }
}
```

`evals/fixtures/react-shadcn/src/lib/utils.ts`
```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

`evals/fixtures/react-shadcn/src/components/ui/button.tsx`
```tsx
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        outline: "border border-input bg-background hover:bg-accent",
      },
      size: { default: "h-9 px-4", sm: "h-8 px-3" },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
);

function Button({
  className,
  variant,
  size,
  ...props
}: React.ComponentProps<"button"> & VariantProps<typeof buttonVariants>) {
  return <button className={cn(buttonVariants({ variant, size, className }))} {...props} />;
}

export { Button, buttonVariants };
```

`evals/fixtures/react-shadcn/src/shared/ui/DataTable.tsx`
```tsx
import * as React from "react";

export type Column<T> = { key: keyof T; header: string };

export function DataTable<T extends { id: string }>({
  columns,
  data,
}: {
  columns: Column<T>[];
  data: T[];
}) {
  return (
    <table>
      <thead>
        <tr>{columns.map((c) => <th key={String(c.key)}>{c.header}</th>)}</tr>
      </thead>
      <tbody>
        {data.map((row) => (
          <tr key={row.id}>
            {columns.map((c) => <td key={String(c.key)}>{String(row[c.key])}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

`evals/fixtures/react-shadcn/src/features/orders/OrdersPage.tsx`
```tsx
import { DataTable } from "@/shared/ui/DataTable";

type Order = { id: string; customer: string; createdAt: string };

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

export function OrdersPage({ orders }: { orders: Order[] }) {
  const rows = orders.map((o) => ({ ...o, createdAt: formatDate(o.createdAt) }));
  return (
    <DataTable
      columns={[{ key: "customer", header: "Customer" }, { key: "createdAt", header: "Created" }]}
      data={rows}
    />
  );
}
```

`evals/fixtures/react-shadcn/src/features/invoices/InvoicesPage.tsx`
```tsx
import { DataTable } from "@/shared/ui/DataTable";

type Invoice = { id: string; number: string; issuedAt: string };

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

export function InvoicesPage({ invoices }: { invoices: Invoice[] }) {
  const rows = invoices.map((i) => ({ ...i, issuedAt: formatDate(i.issuedAt) }));
  return (
    <DataTable
      columns={[{ key: "number", header: "Invoice" }, { key: "issuedAt", header: "Issued" }]}
      data={rows}
    />
  );
}
```

`evals/fixtures/react-shadcn/src/features/customers/CustomerCard.tsx`
```tsx
type Customer = { id: string; name: string; email: string };

export function CustomerCard({ customer }: { customer: Customer }) {
  return (
    <div className="rounded-md border p-4">
      <p className="font-medium">{customer.name}</p>
      <p className="text-sm text-muted-foreground">{customer.email}</p>
    </div>
  );
}
```

`evals/fixtures/react-shadcn/docs/reuse-registry.md`
```markdown
# Reuse Registry

## UI · Primitives
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| Button | src/components/ui/button.tsx | Action button (shadcn) | `variant: default\|outline, size: default\|sm` | 0 | shadcn generated |

## UI · Patterns
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| DataTable | src/shared/ui/DataTable.tsx | Simple data table | `columns, data` | 2 | |
```

`evals/fixtures/react-shadcn/.claude/reusable-dev.md`
```markdown
---
stack: react-next
ui_lib: shadcn-react
shared_paths:
  components: src/shared/ui
  functions: src/shared/lib
commands:
  typecheck: ""
  lint: ""
  test: ""
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
Fixture project for reusable-dev evals. Dependencies are intentionally not installed; all commands are empty.
```

- [ ] **Step 5: Create the harness smoke case**

`evals/00-harness-smoke/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" node-ts
```
Run: `chmod +x evals/00-harness-smoke/setup.sh`

`evals/00-harness-smoke/case.yaml`
```yaml
schema_version: "1.0"
name: 00-harness-smoke
description: Fixture copy works and node-ts tests run inside the eval workspace.
tags: [harness]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Run `node --test` in the current directory and tell me the pass and fail counts."
  max_turns: 5
  allowed_tools: [Bash, Read]
runs: 1
graders:
  - type: regex
    name: tests-pass
    target: trace
    pattern: "# pass 3"
```

- [ ] **Step 6: Run the smoke case**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash --no-publish --ablation none --case 00-harness-smoke`
Expected: `✓ 00-harness-smoke score 1.00`.

- [ ] **Step 7: Commit**

```bash
git add evals/lib evals/fixtures/node-ts evals/fixtures/react-shadcn evals/00-harness-smoke
git commit -m "test: add eval fixtures and harness smoke case"
```

---

### Task 3: Core behavior eval cases (RED) + config and registry format references

**Files:**
- Create: `evals/01-extend-button-react/{case.yaml,setup.sh}`
- Create: `evals/02-reuse-existing-function/{case.yaml,setup.sh}`
- Create: `evals/03-pressure-urgent/{case.yaml,setup.sh}`
- Create: `evals/04-rule-of-three/{case.yaml,setup.sh}`
- Create: `evals/09-negative-readme/{case.yaml,setup.sh}`
- Create: `skills/reusable-dev/references/config-format.md`
- Create: `skills/reusable-dev/references/registry-format.md`

**Interfaces:**
- Consumes: `use-fixture.sh`, fixtures from Task 2.
- Produces: config keys `stack, ui_lib, shared_paths.components, shared_paths.functions, commands.{typecheck,lint,test,build,e2e}, error_style, registry, skills.{design,test,verify,debug,review,plan,e2e}`; registry sections `UI · Primitives`, `UI · Patterns`, `Hooks · Composables`, `Functions · Domain`, `Services`; report line prefixes `Reuse decision:`, `Verified:`, `Notes:` (graders rely on these exact prefixes).

Every `setup.sh` in this task uses the exact template from Task 2 Interfaces with fixture `react-shadcn` (no `--no-config`). Create each and `chmod +x` it.

- [ ] **Step 1: Write case 01**

`evals/01-extend-button-react/case.yaml`
```yaml
schema_version: "1.0"
name: 01-extend-button-react
description: A red delete button must extend the existing Button with a variant, not add a new component.
tags: [core, decide]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a red Delete button to CustomerCard that calls an onDelete prop."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: button-has-destructive-variant
    target: { source: file, path: src/components/ui/button.tsx }
    pattern: "(destructive|danger)\\s*:"
  - type: regex
    name: no-new-button-component
    target: files
    pattern: "(Danger|Delete|Red)Button\\.(tsx|jsx)"
    match: not_contains
  - type: regex
    name: card-uses-button
    target: { source: file, path: src/features/customers/CustomerCard.tsx }
    pattern: "<Button[^>]*variant=[\"'{]+(destructive|danger)"
  - type: regex
    name: reports-decision
    pattern: "Reuse decision:\\s*Extend"
    flags: i
  - type: tool_used
    name: skill-fired
    tool: Skill
    input_match: "reusable-dev"
```

- [ ] **Step 2: Write case 02**

`evals/02-reuse-existing-function/case.yaml`
```yaml
schema_version: "1.0"
name: 02-reuse-existing-function
description: A third date-formatting need must extract the duplicated formatDate into shared, not write a third copy.
tags: [core, decide]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Show each customer's signup date (field signedUpAt, ISO string) on CustomerCard, formatted like the other pages."
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-format-date-created
    target: files
    pattern: "src/shared/lib/[^\\n]*date[^\\n]*\\.ts"
    flags: i
  - type: regex
    name: card-imports-shared
    target: { source: file, path: src/features/customers/CustomerCard.tsx }
    pattern: "from\\s+[\"']@?/?[^\"']*shared/lib/"
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: src/features/orders/OrdersPage.tsx }
    pattern: "function formatDate"
    match: not_contains
  - type: llm
    name: decision-explains-rule-of-three
    criteria: "The final message contains a line starting with 'Reuse decision:' that names formatDate and says it is moved to shared because it now has three uses (or equivalent wording about the third use)."
```

- [ ] **Step 3: Write case 03**

`evals/03-pressure-urgent/case.yaml`
```yaml
schema_version: "1.0"
name: 03-pressure-urgent
description: Under time pressure the skill still searches first and reports a decision.
tags: [core, pressure]
context:
  scaffold_script: setup.sh
execution:
  prompt: "URGENT, demo in 5 minutes. Don't overthink it — just write a new outline-style 'Export' button component for OrdersPage right now."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: no-new-button-file
    target: files
    pattern: "Button\\.(tsx|jsx)"
    match: not_contains
  - type: regex
    name: orders-uses-existing-button
    target: { source: file, path: src/features/orders/OrdersPage.tsx }
    pattern: "<Button[^>]*variant=[\"'{]+outline"
  - type: regex
    name: reports-reuse
    pattern: "Reuse decision:\\s*Reuse"
    flags: i
```

- [ ] **Step 4: Write case 04**

`evals/04-rule-of-three/case.yaml`
```yaml
schema_version: "1.0"
name: 04-rule-of-three
description: A one-off component stays in the feature folder.
tags: [core, decide]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add an OrderStatusTimeline component for the orders page that shows placed → paid → shipped steps with the current step highlighted."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: created-in-feature-folder
    target: files
    pattern: "src/features/orders/[^\\n]*Timeline[^\\n]*\\.tsx"
  - type: regex
    name: not-created-in-shared
    target: files
    pattern: "src/shared/[^\\n]*Timeline"
    match: not_contains
  - type: regex
    name: reports-create
    pattern: "Reuse decision:\\s*Create"
    flags: i
```

- [ ] **Step 5: Write case 09 (should NOT fire)**

`evals/09-negative-readme/case.yaml`
```yaml
schema_version: "1.0"
name: 09-negative-readme
description: A docs-only typo fix must not trigger the skill.
tags: [core, negative]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Fix the typo 'Simple data tabel' → 'Simple data table' if it exists anywhere in docs/, otherwise just tell me there is nothing to fix."
  max_turns: 10
  allowed_tools: [Read, Glob, Grep, Edit, Skill]
graders:
  - type: tool_used
    name: skill-not-fired
    tool: Skill
    input_match: "reusable-dev"
    max: 0
  - type: regex
    name: no-reuse-report
    pattern: "Reuse decision:"
    match: not_contains
```

- [ ] **Step 6: Run the core cases to record RED**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --tag core`
Expected: cases 01–04 score < 1.00 in both arms (no skill exists yet; `reports-decision`/`reports-*` graders fail). Case 09 passes. Copy the case score table into the commit message body.

- [ ] **Step 7: Write `skills/reusable-dev/references/config-format.md`**

````markdown
# Config format — `.claude/reusable-dev.md`

Committed to git so the whole team shares one convention. YAML frontmatter + free-text body (team conventions in prose).

```yaml
---
stack: react-next            # one of references/stacks/*.md names, or a path map for monorepos:
# stack: { "apps/web": react-next, "apps/api": node-ts }
ui_lib: shadcn-react         # one of references/ui-libs/*.md names, or ""
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

| Signal | Value |
|---|---|
| `next.config.*` or `"next"` in package.json deps | `stack: react-next` |
| `nuxt.config.*` or `"nuxt"` / `"vue"` in deps | `stack: vue-nuxt` |
| `svelte.config.*` or `"@sveltejs/kit"` in deps | `stack: sveltekit` |
| `"react"` in deps without next | `stack: react-next` |
| `tsconfig.json` + server framework (`express`, `fastify`, `@nestjs/core`, `hono`) or no UI framework | `stack: node-ts` |
| `components.json` + react | `ui_lib: shadcn-react` |
| `components.json` + vue | `ui_lib: shadcn-vue` |
| `components.json` + svelte | `ui_lib: shadcn-svelte` |
| package.json `scripts` named `typecheck`/`type-check`, `lint`, `test`, `build`, `e2e`/`test:e2e` | `commands.*` = `<pm> run <script>` using the lockfile's package manager |
| Multiple `apps/*` or `packages/*` with different signals | path map for `stack` |

Shared paths: prefer existing dirs in this order — `src/shared/ui`, `src/components/shared`, `src/components/common`, `packages/ui/src` for components; `src/shared/lib`, `src/lib`, `packages/shared/src` for functions. Ignore the ui-lib primitives dir (`components/ui`) — it is covered by `ui_lib`.

## Missing config (skill step 0)

1. Detect every key above that has a signal.
2. Ask at most 3 questions in ONE message, only for keys with no signal (usually `shared_paths` and `error_style`). Offer the detected default as the first option.
3. Write `.claude/reusable-dev.md` with all keys; `skills` all `[]` (full skill wiring is `/reusable-dev:reuse-setup`).
4. No way to ask (non-interactive run) or the user skips → do not write the file; continue with detected values and defaults (`error_style: throw`, `registry: docs/reuse-registry.md`) and add `config not saved — run /reusable-dev:reuse-setup` to the report Notes.
5. Never ask again in a project where the file exists. Changes happen by editing the file or re-running `/reusable-dev:reuse-setup`.
````

- [ ] **Step 8: Write `skills/reusable-dev/references/registry-format.md`**

````markdown
# Registry format — `docs/reuse-registry.md`

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
````

- [ ] **Step 9: Commit**

```bash
git add evals/01-extend-button-react evals/02-reuse-existing-function evals/03-pressure-urgent evals/04-rule-of-three evals/09-negative-readme skills/reusable-dev/references/config-format.md skills/reusable-dev/references/registry-format.md
git commit -m "test: add core reuse behavior evals (RED) and config/registry formats"
```

---

### Task 4: Component and function design references

**Files:**
- Create: `skills/reusable-dev/references/component-design.md`
- Create: `skills/reusable-dev/references/function-design.md`

**Interfaces:**
- Consumes: `error_style` config key (Task 3).
- Produces: rule IDs referenced by `/reusable-dev:reuse-audit` and `duplicate-finder`: `C1`–`C8` (components), `F1`–`F8` (functions).

- [ ] **Step 1: Write `component-design.md`**

````markdown
# Component design rules

Principles → checkable rules → anti-patterns → example. Stack syntax lives in `stacks/<stack>.md`; ui-lib specifics in `ui-libs/<ui_lib>.md`.

## Layers

`primitives` (Button, Input) → `patterns` (FormField, DataTable) → `feature` (OrdersTable) → `page`.
A layer may import only from layers to its left. Shared code (`primitives`, `patterns`) never imports from `feature` or `page`.

## Rules

| ID | Rule | How to check |
|---|---|---|
| C1 | Shared components import nothing from feature/page folders. | grep imports in `shared_paths.components` for `features/` or `pages/`/`app/` |
| C2 | State and effects live in a hook/composable; the component renders. Shared UI does not fetch data. | no `fetch`/data-client calls in shared UI files |
| C3 | Visual alternatives are one `variant` (or `size`) enum prop, not booleans. | no props named `is<Adjective>` that change appearance |
| C4 | Content goes through children/slots, not config props (`title`, `footerText`, `icon`…) when it can be markup. | ≤ 2 string content props |
| C5 | Pass through remaining native props and ref to the root element. | rest spread on root element |
| C6 | Inputs support controlled (`value` + `onChange`) and uncontrolled (`defaultValue`) use. | both prop pairs present on form controls |
| C7 | No hardcoded user-facing text or colors in shared UI; use props/i18n and design tokens. | no hex/rgb literals; no literal sentences |
| C8 | Accessible baseline: semantic element, keyboard operable, labelled. | `button` not clickable `div`; inputs have label/aria-label |

## Warning signals (consider splitting or composing)

- More than 7 props.
- Two or more booleans that cannot be true together (`isPrimary` + `isDanger`).
- A copy of a component with a small change (`BlueCard` next to `Card`).
- A prop that is only passed through to one child (prop drilling across > 2 levels → context/provide).

## Extend without breaking

- New props are optional with a default equal to today's behavior.
- Never rename or remove a prop in the same change that adds one. Deprecate first: keep the old prop, map it to the new one, note `deprecated → <new>` in the registry.

## Example (framework-neutral pseudocode)

```
// ✗ Before: booleans + copied component
<Button isDanger />         <DangerButton />

// ✓ After: one variant enum on the existing primitive
<Button variant="destructive" />
```
````

- [ ] **Step 2: Write `function-design.md`**

````markdown
# Function and service design rules

Principles → checkable rules → anti-patterns → example.

## Layers

`lib/domain` (pure) → `services` (orchestrate IO) → `handlers/adapters` (HTTP, CLI, jobs, UI actions).
Pure code never imports services or adapters. When frontend and backend share a language, domain code shared by both lives in a shared package (`packages/shared`), not duplicated.

## Rules

| ID | Rule | How to check |
|---|---|---|
| F1 | Business logic is a pure function: same input → same output, no IO, no clock, no randomness. | no `fetch`, db client, `Date.now()`, `Math.random()` in `lib/domain` files |
| F2 | IO dependencies are parameters (or constructor args), not imports inside logic. | services receive clients; tests pass fakes |
| F3 | One responsibility; the name states intent (`calculateInvoiceTotal`, not `process`). | name is verb + noun; body ≤ ~40 lines |
| F4 | ≤ 3 positional parameters; more → one options object with defaults. | signature check |
| F5 | No boolean flag that switches behavior; split into two functions. | no `(…, isX: boolean)` that branches the whole body |
| F6 | Errors follow `error_style`: `throw` → throw typed errors (`class NotFoundError extends Error`); `result` → return `{ ok: true, value } \| { ok: false, error }`. Never mix in one module. | grep for the other style |
| F7 | Explicit input and return types on exported functions. | exported signatures typed |
| F8 | No catch-all `utils` file; group by domain (`money.ts`, `dates.ts`). | no `utils.*`/`helpers.*` over ~5 unrelated exports (ui-lib `cn()` helper is exempt) |

## Anti-patterns

- Hidden globals or module-level mutable state.
- Generic-for-its-own-sake: type parameters or options no caller uses.
- Copy-paste with one changed literal → parameterize the literal.

## Extend without breaking

- Add an optional parameter or a new options field with a default; existing calls stay valid.
- Changing a positional signature to an options object: keep an overload or wrapper for the old form, or update every call site in the same change and list them in the report.

## Example

```ts
// ✗ Before: IO + flag + positional sprawl
export async function report(userId, from, to, format, includeTax) { const rows = await db.query(…); … }

// ✓ After: pure core + injected IO + options object
export function summarize(rows: Row[], opts: { includeTax?: boolean } = {}): Summary { … }
export async function buildReport(deps: { db: Db }, q: { userId: string; from: Date; to: Date }) {
  return summarize(await deps.db.rows(q));
}
```
````

- [ ] **Step 2b: Check line limits**

Run: `wc -l skills/reusable-dev/references/component-design.md skills/reusable-dev/references/function-design.md`
Expected: each ≤ 150.

- [ ] **Step 3: Commit**

```bash
git add skills/reusable-dev/references/component-design.md skills/reusable-dev/references/function-design.md
git commit -m "feat: add component and function design references"
```

---

### Task 5: Verification and integration references + SKILL.md (GREEN for core evals)

**Files:**
- Create: `skills/reusable-dev/references/verification.md`
- Create: `skills/reusable-dev/references/integration.md`
- Create: `skills/reusable-dev/SKILL.md`

**Interfaces:**
- Consumes: config keys (Task 3), rule IDs (Task 4), report prefixes (Task 3).
- Produces: skill `reusable-dev`; report format used by every later eval.

- [ ] **Step 1: Write `verification.md`**

````markdown
# Verification

Report only what you ran, with the real result. A tier with no command is `skipped`, never `✓`.

## Tiers

| Tier | What | When |
|---|---|---|
| T1 | `commands.typecheck`, `commands.lint`, `commands.build` | every code change |
| T2 | `commands.test` scoped to touched units (shared units must have tests) | every code change |
| T3 | tests of every call site of a changed shared unit | a shared unit's code or API changed |
| T4 | `commands.e2e` or extension point `e2e` | `/reusable-dev:reuse-verify` only |

## Finding call sites (T3)

1. Use LSP find-references on the exported symbol if an LSP tool is available.
2. Otherwise grep for the import path without extension (e.g. `shared/lib/money`) and for the symbol name.
3. For each caller, run its colocated test file(s) (`*.test.*`, `*.spec.*`, `__tests__/`). If the test runner cannot target files, run the full `commands.test` once.
4. Caller with no test → list it under Notes as `untested call site: <path>`.

## Report format

```
Verified: T1 typecheck ✓ lint skipped (no command) · T2 4 tests ✓ · T3 2 call sites, 3 tests ✓
```
Failure: `T2 1 failing (money.test.ts: formats USD)` and stop to debug — do not claim done.

## Built-in fallbacks (used when the extension point is empty or its skill is missing)

**test** — Write the test for the shared unit before the code: cover the default behavior, each variant/option, and the backward-compatible path. Run it and see it fail for the right reason, then implement.

**verify** — Before any "done" statement: run the configured commands for T1–T3 now, read the output, and put the numbers in the report.

**debug** — Read the full failure. Reproduce it with one command. Find the cause in the changed unit before editing anything. Change one thing, rerun. Never weaken or delete an assertion to get green; if the behavior change is intended, update the test and say so in Notes.

**review** — For a changed shared API: (1) every existing call compiles and behaves the same, or is updated in this change; (2) new props/params are optional with defaults; (3) removed/renamed items are deprecated, not deleted; (4) registry row updated.
````

- [ ] **Step 2: Write `integration.md`**

````markdown
# Extension points and working with other skills

reusable-dev depends on roles, not on specific skills. Nothing here is required.

## Extension points

| Point | Runs at | Example skills (optional) | Fallback |
|---|---|---|---|
| `design` | workflow step 3 | `mattpocock-skills:codebase-design`, `frontend-design:frontend-design` | component-design.md / function-design.md |
| `test` | step 3, shared units | `superpowers:test-driven-development`, `mattpocock-skills:tdd` | verification.md → test |
| `verify` | step 4 | `superpowers:verification-before-completion` | verification.md → verify |
| `debug` | a test fails | `superpowers:systematic-debugging`, `mattpocock-skills:diagnosing-bugs` | verification.md → debug |
| `review` | shared API changed | `pr-review-toolkit:code-reviewer` | verification.md → review |
| `plan` | `/reusable-dev:reuse-audit` finds a large refactor | `superpowers:writing-plans` | numbered steps in the audit report |
| `e2e` | `/reusable-dev:reuse-verify` | `chrome-devtools-mcp:chrome-devtools`, `run` | `commands.e2e` |

## Rules

1. Empty list → use the fallback.
2. Listed skill not in your available skills → use the fallback and add `skill <name> not installed → fallback` to Notes once. Never stop the workflow for this.
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
````

- [ ] **Step 3: Write `SKILL.md`**

````markdown
---
name: reusable-dev
description: Use when about to create or modify a UI component, hook/composable, function, utility, service, or module in an application codebase, or when planning tasks that will. Finds existing reusable code first, decides Reuse → Extend → Compose → Create, applies design rules for the project's stack and UI library, verifies with typecheck/lint/tests including call sites of changed shared code, and keeps a reuse registry. Thai triggers - สร้าง component, เขียน function, เพิ่มปุ่ม, เพิ่มฟีเจอร์, reuse, shared component, โค้ดซ้ำ. Not for docs-only, config-only, or other non-code edits.
---

# Reusable Dev

Make components and functions easy to find, reuse, and change safely. This skill owns the reuse workflow and works without any other plugin.

## The rule

Before creating or changing a component, hook/composable, function, utility, service, or module, run the workflow. No new unit without a `Reuse decision:` line. "Writing a new one is faster" is the exact thought this skill exists to stop — Discover takes under a minute.

## Workflow

### 0. Load config
Read `.claude/reusable-dev.md`. Missing → follow "Missing config" in `references/config-format.md`.

### 1. Discover
1. Grep the registry file (config `registry`) for the thing you need plus 2–3 synonyms (button/btn/action · date/format/time · price/money/currency).
2. Confirm each hit's path exists. Missing → Notes: `registry stale — run /reusable-dev:reuse-registry --sync`.
3. Grep `shared_paths` and the whole `src/` for the same terms and for similar function bodies or prop names. Duplicates inside feature folders count.
4. `ui_lib` set → check its primitives directory, then its CLI registry (`references/ui-libs/<ui_lib>.md`).

### 2. Decide
Pick the FIRST option that works, and say why earlier options do not:
1. **Reuse** — use the existing unit as is.
2. **Extend** — add an optional prop/parameter (or variant) with a default; existing call sites unchanged.
3. **Compose** — build a new unit from existing ones.
4. **Create** — new unit. One use → feature folder. Move to shared only when the second or third real use appears (Rule of Three); when you find two local copies and need a third, extract to shared and replace the copies.

### 3. Design
Load only what applies:
- UI → `references/component-design.md`; logic → `references/function-design.md`
- `references/stacks/<stack>.md` if present (unknown stack → general rules; Notes: `no stack reference for <stack> — /reusable-dev:reuse-setup can add one`)
- `references/ui-libs/<ui_lib>.md` if `ui_lib` is set
- Extension points `design`, `test` → `references/integration.md`
New or changed shared unit → write its test first.

### 4. Verify
Run T1–T3 per `references/verification.md` (extension points `verify`, `debug`). Never report a tier you did not run.

### 5. Register
Created a shared unit or changed a shared API → update its registry row (`references/registry-format.md`). Changed a shared API → extension point `review`.

## When planning instead of coding

Writing a design or implementation plan (with any planning skill or none): do Discover + Decide for each task and put a `Reuse decision:` line in every task that creates or changes code. Implementers who never load this skill still see it.

## Report — always end with

```
Reuse decision: <Reuse|Extend|Compose|Create> <unit> (<path>) — <one-line why>
Verified: T1 … · T2 … · T3 …
Notes: <fallbacks, skipped tiers, stale registry, config not saved — or "none">
```
One `Reuse decision:` line per unit touched.

## Red flags

| Thought | Reality |
|---|---|
| "User said urgent, skip the search" | Discover is the fast path. Do it, keep it short. |
| "A new DangerButton is simpler" | A variant on Button is Extend. |
| "Put it in shared, it might be reused" | One use = feature folder. |
| "There are two copies already, a third is fine" | Third use = extract to shared now. |
| "Tests probably pass" | Run them, or write `skipped (no command)`. |
| "Loosen the call-site test so it passes" | Keep the API backward compatible or update the caller. |
````

- [ ] **Step 4: Check sizes**

Run: `wc -l skills/reusable-dev/SKILL.md skills/reusable-dev/references/verification.md skills/reusable-dev/references/integration.md && claude plugin validate .`
Expected: SKILL.md ≤ 125 lines total (body ≤ 120), references ≤ 150; validate PASS with no errors.

- [ ] **Step 5: Run core evals (GREEN)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --tag core`
Expected: with-plugin arm: 01, 02, 03, 04, 09 each score 1.00; without-plugin arm lower on 01–04.

If a case fails in the with-plugin arm: open its trace (`tracePath` in `evals/results/<ts>/aggregate-result.json`), find the sentence Claude used to skip a step, add that rationalization as a row in the Red flags table (or tighten the step wording), and rerun only that case with `--case <name>`. Repeat until green. Do not edit graders to make a case pass unless the grader is provably wrong (e.g. path regex mismatch) — record any grader fix in the commit body.

- [ ] **Step 6: Commit**

```bash
git add skills/reusable-dev
git commit -m "feat: add reusable-dev skill workflow with verification and integration references"
```

---

### Task 6: Stack references (react-next, vue-nuxt, sveltekit, node-ts)

**Files:**
- Create: `skills/reusable-dev/references/stacks/_template.md`
- Create: `skills/reusable-dev/references/stacks/react-next.md`, `vue-nuxt.md`, `sveltekit.md`, `node-ts.md`

**Interfaces:**
- Consumes: stack names from `config-format.md` detection table.
- Produces: files loaded by SKILL.md step 3 as `references/stacks/<stack>.md`; `_template.md` used by `/reusable-dev:reuse-setup`.

- [ ] **Step 1: Write `_template.md`**

````markdown
# Stack: <name>

## Detection
<files and dependencies that identify this stack>

## Reuse units
<what a reusable component / stateful logic unit / function / module is called here, with file naming>

## Paths
<conventional locations for primitives, patterns, hooks/composables, domain functions, services; server vs client code split>

## Component idioms
<how this stack expresses component-design.md rules C3–C6: variants, children/slots, rest props + ref, controlled/uncontrolled — short code>

## Logic idioms
<how function-design.md rules F2 and F6 look here: dependency injection pattern, typed errors / result type — short code>

## Testing
<test runner, component testing library, how to run tests for one file (needed for T2/T3), default commands>

## Stack-specific anti-patterns
<3–6 bullets>
````

- [ ] **Step 2: Research current idioms (one query set per stack)**

Use context7 (`resolve-library-id` then `query-docs`) and record the library versions found in each file's first line as `<!-- researched 2026-09-14: <lib>@<version>, … -->`.

| File | Libraries to query | Questions to answer |
|---|---|---|
| react-next.md | `next`, `react`, `vitest`, `@testing-library/react` | Server vs Client Component boundaries (`"use client"`), is `forwardRef` still needed (React 19 ref-as-prop), App Router colocation conventions, running a single Vitest file |
| vue-nuxt.md | `nuxt`, `vue`, `@vue/test-utils`, `vitest` | `defineProps`/`defineModel` for controlled inputs, slots, composables auto-import dirs (`composables/`, `utils/`), Nuxt layers for sharing, `server/` vs app code, `@nuxt/test-utils` single-file runs |
| sveltekit.md | `@sveltejs/kit`, `svelte`, `vitest`, `@testing-library/svelte` | Svelte 5 runes (`$props`, `$bindable`), snippets vs slots, `$lib` and `$lib/server`, rest props, running a single test file |
| node-ts.md | `typescript`, `vitest`, `node` (test runner) | Module layout for services/handlers, constructor vs function DI, typed error classes, `Result` type pattern, `node --test` / Vitest single-file runs, sharing code via workspaces (`packages/shared`) |

- [ ] **Step 3: Write each stack file from the template**

Each file must fill every template section with the researched facts and must include these stack-specific rules:

- **react-next.md:** shared UI in `src/shared/ui` or `components/`; client-only code marked `"use client"` only at the leaf that needs it, shared primitives stay server-compatible when possible; data fetching in Server Components or route handlers, never inside shared UI (C2); stateful logic in `use*` hooks under `src/shared/hooks`; anti-patterns: `useEffect` for derived state, context for everything, barrel files that pull client code into server bundles.
- **vue-nuxt.md:** shared UI in `components/` (Nuxt auto-import) with a `Base`/`App` prefix or `components/ui`; stateful logic in `composables/use*.ts`; pure helpers in `utils/` or `shared/`; controlled inputs via `defineModel`; content via slots (C4); cross-app sharing via Nuxt layers; server code only in `server/`; anti-patterns: mixins, `this.$parent`, global event bus, business logic inside `pages/`.
- **sveltekit.md:** shared UI in `src/lib/components`; server-only code in `src/lib/server` (never imported by components); stateful logic as `.svelte.ts` modules using runes; content via snippets (C4); `$bindable` for controlled inputs; rest props spread; anti-patterns: stores for local state in Svelte 5 code, fetching in components instead of `load`, importing `$lib/server` from client code.
- **node-ts.md:** layout `src/domain` (pure) → `src/services` (IO orchestration) → `src/http|routes|jobs` (adapters); DI via factory functions taking a `deps` object; typed errors (`throw`) or `Result` (`result`) per `error_style`; shared code for web+api in a workspace package; single-file test command; anti-patterns: services importing HTTP request objects, singletons created at import time, `utils/` dumping ground.

- [ ] **Step 4: Check sizes**

Run: `wc -l skills/reusable-dev/references/stacks/*.md`
Expected: each ≤ 150.

- [ ] **Step 5: Verify react-next reference is used (extends case 01 evidence)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case 01-extend-button-react`
Expected: score 1.00; trace contains a Read of `references/stacks/react-next.md` (check with `grep -c "stacks/react-next.md" <tracePath>` ≥ 1).

- [ ] **Step 6: Commit**

```bash
git add skills/reusable-dev/references/stacks
git commit -m "feat: add phase 1 stack references"
```

---

### Task 7: UI library references (shadcn) + Vue and Svelte fixtures and evals

**Files:**
- Create: `skills/reusable-dev/references/ui-libs/_template.md`, `shadcn-core.md`, `shadcn-react.md`, `shadcn-vue.md`, `shadcn-svelte.md`
- Create: `evals/fixtures/vue-shadcn/**`, `evals/fixtures/svelte-shadcn/**`
- Create: `evals/01b-extend-button-vue/{case.yaml,setup.sh}`, `evals/01c-extend-button-svelte/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: `ui_lib` names from `config-format.md`.
- Produces: files loaded by SKILL.md step 3 as `references/ui-libs/<ui_lib>.md` (port files start with `Read shadcn-core.md first.`).
- Fixture facts: vue-shadcn has `src/components/ui/button/Button.vue` + `src/components/ui/button/index.ts` (cva `buttonVariants` with `default | outline`) and `src/features/customers/CustomerCard.vue`; svelte-shadcn has `src/lib/components/ui/button/button.svelte` + `index.ts` (tailwind-variants or cva per researched current shadcn-svelte, variants `default | outline`) and `src/routes/customers/CustomerCard.svelte`.

- [ ] **Step 1: Research current shadcn ports**

context7 / official docs queries — record versions in each file's first line comment:
- shadcn/ui (React): current CLI name and `add` syntax, `components.json` fields, namespaced registries (`registries` in components.json, `@namespace/item`), `registry.json` / `registry-item.json` schema.
- shadcn-vue: current repo/org and primitive library (Reka UI), CLI command (`shadcn-vue add`), file layout `components/ui/<name>/index.ts` + `.vue`, variants location.
- shadcn-svelte: current CLI (`shadcn-svelte add`), primitive library (Bits UI), Svelte 5 file layout, variant helper used (tailwind-variants vs cva).

- [ ] **Step 2: Write `ui-libs/_template.md`**

````markdown
# UI library: <name>

## Detection
## Primitives location
## Adding a primitive (CLI)
## Customizing without forking
## Cross-project sharing
## Anti-patterns
````

- [ ] **Step 3: Write `shadcn-core.md`**

````markdown
# UI library family: shadcn (all ports)

<!-- researched 2026-09-14: shadcn@<version> -->

shadcn copies component source into the project (copy-in). The code is yours, so reuse discipline does not come from a package manager — it comes from these rules.

## Rules

| ID | Rule |
|---|---|
| S1 | `components/ui/*` is the primitives layer. Before writing any primitive, check in order: already in `components/ui` → available via the port's CLI `add` → available in a team registry listed in `components.json`. Found → add it with the CLI. Never hand-write a primitive the registry has. |
| S2 | Change primitives as little as possible. New look → add a variant to the existing variants definition (`cva`/`tv`). New behavior or composition → wrap it in the patterns layer (`shared_paths.components`). |
| S3 | If a generated file must be edited beyond a variant, add `shadcn modified: <what>` to its registry Notes so a later CLI update does not silently overwrite it. |
| S4 | Merge classes with the port's `cn()` helper; colors come from CSS variables/tokens, never hex literals. |
| S5 | A component reused across projects → propose a private namespaced registry (`@team/<item>`) generated by `/reusable-dev:reuse-registry`. |

## Discover checklist

1. `ls` the primitives dir from `components.json` aliases.
2. Run or recall the port's CLI list/search for the needed name.
3. Check `registries` in `components.json` for team namespaces.

Port-specific syntax: `shadcn-react.md`, `shadcn-vue.md`, `shadcn-svelte.md`.
````

- [ ] **Step 4: Write the three port files from the template**

Each starts with `Read shadcn-core.md first.` and the researched-version comment, fills every template section, and includes a ≤ 15-line example of adding a `destructive` variant to Button in that port's syntax plus the wrapper-in-patterns example for S2. Keep each ≤ 150 lines.

- [ ] **Step 5: Create vue-shadcn fixture**

Mirror react-shadcn (Task 2 Step 4) with Vue files, using the file layout confirmed in Step 1:
- `package.json` (deps `vue`, `class-variance-authority`, `clsx`, `tailwind-merge`, `reka-ui`), `components.json` (shadcn-vue schema from research), `src/lib/utils.ts` (`cn`), `src/components/ui/button/index.ts` (exports `Button` and `buttonVariants` with variants `default | outline`, size `default | sm`), `src/components/ui/button/Button.vue` (`<script setup lang="ts">` with `variant`, `size`, `class` props, renders `<button :class="cn(buttonVariants({ variant, size }), props.class)"><slot /></button>`), `src/features/customers/CustomerCard.vue` (props `customer: {id,name,email}`, same markup as the React card), `docs/reuse-registry.md` (Button row path `src/components/ui/button/Button.vue`), `.claude/reusable-dev.md` (`stack: vue-nuxt`, `ui_lib: shadcn-vue`, `shared_paths.components: src/components/shared`, all commands `""`).

- [ ] **Step 6: Create svelte-shadcn fixture**

Same pattern with the layout confirmed in Step 1:
- `package.json` (deps `svelte`, `@sveltejs/kit`, `bits-ui`, `clsx`, `tailwind-merge`, plus the variant helper found in research), `components.json` (shadcn-svelte schema), `src/lib/utils.ts` (`cn`), `src/lib/components/ui/button/button.svelte` (Svelte 5 `$props()` with `variant`, `size`, `class`, `children`, rest props; variants `default | outline`), `src/lib/components/ui/button/index.ts`, `src/routes/customers/CustomerCard.svelte`, `docs/reuse-registry.md`, `.claude/reusable-dev.md` (`stack: sveltekit`, `ui_lib: shadcn-svelte`, `shared_paths.components: src/lib/components/shared`, all commands `""`).

- [ ] **Step 7: Write cases 01b and 01c**

`evals/01b-extend-button-vue/setup.sh` uses fixture `vue-shadcn`; `evals/01c-extend-button-svelte/setup.sh` uses fixture `svelte-shadcn` (template from Task 2).

`evals/01b-extend-button-vue/case.yaml`
```yaml
schema_version: "1.0"
name: 01b-extend-button-vue
description: Vue port — red delete button extends Button variants.
tags: [core, stack]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a red Delete button to CustomerCard that emits a delete event."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: variants-have-destructive
    target: { source: file, path: src/components/ui/button/index.ts }
    pattern: "(destructive|danger)\\s*:"
  - type: regex
    name: no-new-button-component
    target: files
    pattern: "(Danger|Delete|Red)Button\\.vue"
    match: not_contains
  - type: regex
    name: reports-extend
    pattern: "Reuse decision:\\s*Extend"
    flags: i
```

`evals/01c-extend-button-svelte/case.yaml`
```yaml
schema_version: "1.0"
name: 01c-extend-button-svelte
description: Svelte port — red delete button extends Button variants.
tags: [core, stack]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a red Delete button to CustomerCard that calls an ondelete prop."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: variants-have-destructive
    target: { source: file, path: src/lib/components/ui/button/button.svelte }
    pattern: "(destructive|danger)\\s*:"
  - type: regex
    name: no-new-button-component
    target: files
    pattern: "(danger|delete|red)-?button\\.svelte"
    flags: i
    match: not_contains
  - type: regex
    name: reports-extend
    pattern: "Reuse decision:\\s*Extend"
    flags: i
```

If Step 1 research shows the variants live in a different file than the grader path (e.g. Svelte variants in `index.ts`), change the grader `path` to the fixture's actual variants file before running.

- [ ] **Step 8: Run the stack cases**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --tag stack`
Expected: with-plugin arm 1.00 for both. Fix failures as in Task 5 Step 5.

- [ ] **Step 9: Commit**

```bash
git add skills/reusable-dev/references/ui-libs evals/fixtures/vue-shadcn evals/fixtures/svelte-shadcn evals/01b-extend-button-vue evals/01c-extend-button-svelte
git commit -m "feat: add shadcn ui-lib references with vue and svelte evals"
```

---

### Task 8: Verification, fallback, and config behavior evals

**Files:**
- Create: `evals/05-shared-signature-call-sites/{case.yaml,setup.sh}` (fixture `node-ts`)
- Create: `evals/07-missing-extension-skill/{case.yaml,setup.sh}` (fixture `node-ts`, then edits config — see Step 2)
- Create: `evals/08a-no-config/{case.yaml,setup.sh}` (fixture `react-shadcn --no-config`)
- Create: `evals/08b-config-present-no-questions/{case.yaml,setup.sh}` (fixture `react-shadcn`)
- Modify (only if a case fails): `skills/reusable-dev/SKILL.md`, `references/verification.md`, `references/config-format.md`

**Interfaces:**
- Consumes: node-ts fixture facts (Task 2), report format (Task 5).

- [ ] **Step 1: Write case 05**

`evals/05-shared-signature-call-sites/case.yaml`
```yaml
schema_version: "1.0"
name: 05-shared-signature-call-sites
description: Changing a shared function's signature runs and passes call-site tests (T3).
tags: [behavior, verify]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Change formatCurrency to take an options object: formatCurrency(amount, { currency, locale }) where locale defaults to en-US."
  max_turns: 35
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: signature-has-options
    target: { source: file, path: src/shared/lib/money.ts }
    pattern: "locale"
  - type: regex
    name: orders-call-site-updated
    target: { source: file, path: src/features/orders/order-summary.ts }
    pattern: "formatCurrency\\([\\s\\S]*?\\{\\s*currency"
  - type: regex
    name: invoices-call-site-updated
    target: { source: file, path: src/features/invoices/invoice-total.ts }
    pattern: "formatCurrency\\([\\s\\S]*?\\{\\s*currency"
  - type: regex
    name: tests-ran-green
    target: trace
    pattern: "# fail 0"
  - type: regex
    name: reports-t3
    pattern: "T3[^\\n]*(2 call sites|call sites?)"
    flags: i
  - type: regex
    name: registry-api-updated
    target: { source: file, path: docs/reuse-registry.md }
    pattern: "formatCurrency[^\\n]*locale"
```

- [ ] **Step 2: Write case 07**

`evals/07-missing-extension-skill/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" node-ts
sed -i.bak 's/^  test: \[\]$/  test: [nonexistent-plugin:super-tdd]/' .claude/reusable-dev.md
rm .claude/reusable-dev.md.bak
```

`evals/07-missing-extension-skill/case.yaml`
```yaml
schema_version: "1.0"
name: 07-missing-extension-skill
description: A configured but missing extension skill falls back without stopping.
tags: [behavior, fallback]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a shared function roundToCents(amount: number): number next to formatCurrency, and use it in invoiceTotal before formatting."
  max_turns: 35
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: function-added
    target: { source: file, path: src/shared/lib/money.ts }
    pattern: "export function roundToCents"
  - type: regex
    name: notes-fallback
    pattern: "nonexistent-plugin:super-tdd[^\\n]*(not installed|fallback)"
    flags: i
  - type: regex
    name: tests-ran-green
    target: trace
    pattern: "# fail 0"
```

- [ ] **Step 3: Write case 08a**

`evals/08a-no-config/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" react-shadcn --no-config
```

`evals/08a-no-config/case.yaml`
```yaml
schema_version: "1.0"
name: 08a-no-config
description: Without config in a non-interactive run, detect values, do not write config, note it, and still do the work.
tags: [behavior, config]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add a red Delete button to CustomerCard that calls an onDelete prop."
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: still-extends-button
    target: { source: file, path: src/components/ui/button.tsx }
    pattern: "(destructive|danger)\\s*:"
  - type: llm
    name: detected-and-noted
    criteria: "Either (a) the final message's Notes say the config was not saved and suggest /reusable-dev:reuse-setup, or (b) a .claude/reusable-dev.md file was created containing stack: react-next and ui_lib: shadcn-react. Pass if (a) or (b) is true."
    focus: trace
```

- [ ] **Step 4: Write case 08b**

`evals/08b-config-present-no-questions/case.yaml` (setup: fixture `react-shadcn`)
```yaml
schema_version: "1.0"
name: 08b-config-present-no-questions
description: With config present, no setup questions are asked.
tags: [behavior, config]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Add an outline 'Edit' button to CustomerCard that calls an onEdit prop."
  max_turns: 25
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill, AskUserQuestion]
graders:
  - type: tool_used
    name: no-questions
    tool: AskUserQuestion
    max: 0
  - type: regex
    name: uses-outline-button
    target: { source: file, path: src/features/customers/CustomerCard.tsx }
    pattern: "variant=[\"'{]+outline"
```

- [ ] **Step 5: Run behavior cases**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --tag behavior`
Expected: with-plugin arm 1.00 for 05, 07, 08a, 08b. For each failure, read the trace, tighten the relevant reference or SKILL.md step (not the grader), rerun that case.

- [ ] **Step 6: Commit**

```bash
git add evals/05-shared-signature-call-sites evals/07-missing-extension-skill evals/08a-no-config evals/08b-config-present-no-questions skills/reusable-dev
git commit -m "test: add verification, fallback, and config behavior evals"
```

---

### Task 9: duplicate-finder agent + /reuse-audit command

**Files:**
- Create: `agents/duplicate-finder.md`
- Create: `commands/reuse-audit.md`
- Create: `evals/10-audit-reports-without-editing/{case.yaml,setup.sh}` (fixture `react-shadcn`)

**Interfaces:**
- Consumes: rule IDs C1–C8, F1–F8, S1–S5; config keys.
- Produces: agent `duplicate-finder` returning findings in this exact format (the command parses it):
  ```
  FINDING | <kind: duplicate|rule|untested-shared|handwritten-primitive> | <rule id or -> | <impact 1-5> | <path:line>[, <path:line>…] | <suggestion>
  ```

- [ ] **Step 1: Write case 10 (RED)**

`evals/10-audit-reports-without-editing/case.yaml`
```yaml
schema_version: "1.0"
name: 10-audit-reports-without-editing
description: /reuse-audit finds the duplicated formatDate and edits nothing.
tags: [command]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-audit src"
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Bash, Agent, Edit, Write]
graders:
  - type: regex
    name: finds-format-date-duplicate
    pattern: "formatDate[\\s\\S]*(OrdersPage|InvoicesPage)"
  - type: tool_used
    name: no-edits
    tool: Edit
    max: 0
  - type: tool_used
    name: no-writes
    tool: Write
    max: 0
  - type: llm
    name: prioritized-and-asks
    criteria: "The final message lists findings ordered by impact (highest first) and ends by asking the user which findings to act on."
```

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case 10-audit-reports-without-editing`
Expected: FAIL (command does not exist).

- [ ] **Step 2: Write `agents/duplicate-finder.md`**

````markdown
---
name: duplicate-finder
description: Read-only scanner for reusable-dev. Use when /reusable-dev:reuse-audit (or the main agent) needs duplicated code, reuse-rule violations, untested shared units, or hand-written UI primitives found across a directory without loading file contents into the main context. Returns one FINDING line per issue.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You scan a codebase for reuse problems and report findings. You never edit files.

## Input
The prompt gives: scan path(s), `shared_paths`, `ui_lib`, `stack`, and the absolute path of the reusable-dev references directory.

## Procedure
1. Read `component-design.md`, `function-design.md`, and (if `ui_lib` starts with `shadcn`) `ui-libs/shadcn-core.md` from the references directory.
2. Duplicates:
   - If `npx --no-install jscpd --version` succeeds, run `npx --no-install jscpd --min-lines 5 --reporters json --output /tmp/reusable-dev-jscpd <paths>` and read the JSON.
   - Otherwise grep for function/component declarations (`function \w+`, `const \w+ = (`, `export default`), group identical names across files, and read those declarations to compare bodies. Also grep for identical literal-heavy lines (format strings, regexes, URLs) appearing in 2+ files.
3. Rule violations: check each rule's "How to check" column against files under the scan paths (C1–C8 for UI files, F1–F8 for logic files, S1–S5 when shadcn).
4. Untested shared units: every export under `shared_paths` without a colocated `*.test.*`/`*.spec.*`.
5. Hand-written primitives (shadcn only): components outside `components/ui` whose name matches a known shadcn primitive (Button, Input, Dialog, Select, Table, Card, Badge, Tabs, Tooltip, Dropdown Menu, Checkbox, Switch, Textarea, Label, Sheet, Popover).

## Impact score
`impact = min(5, occurrences + (lines ≥ 20 ? 1 : 0) + (in shared ? 1 : 0))` for duplicates; rule violations 2 (C1, F1, S1 = 3); untested shared 2; hand-written primitive 3.

## Output — only these lines, highest impact first, nothing else
```
FINDING | duplicate | - | 3 | src/features/orders/OrdersPage.tsx:5, src/features/invoices/InvoicesPage.tsx:5 | Extract formatDate to src/shared/lib/format-date.ts
```
No file contents, no preamble. If nothing is found: `NO_FINDINGS`.
````

- [ ] **Step 3: Write `commands/reuse-audit.md`**

````markdown
---
description: Scan for duplicated code and reuse-rule violations, report prioritized findings without editing
argument-hint: "[path]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Agent"]
---

# Reuse audit

Scope: "$ARGUMENTS"

1. Read `.claude/reusable-dev.md`. Missing → use detection from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md` without writing the file.
2. Scope: the argument path if given; otherwise `shared_paths` plus files changed in the last 20 commits (`git log --name-only -20 --pretty=format:`), existing files only.
3. Dispatch the `duplicate-finder` agent with: scope paths, `shared_paths`, `ui_lib`, `stack`, and references dir `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references`.
4. Do NOT edit or create files in this command.
5. Report:

```
## Reuse audit — <scope>
| # | Impact | Kind | Rule | Where | Suggestion |
|---|---|---|---|---|---|
```
Rows from the agent's FINDING lines, highest impact first. After the table: findings with 3+ locations or touching 5+ files are marked `large` — for those, say they should go through extension point `plan` (see `integration.md`) before any edit.

6. End with: "Which findings should I fix? (numbers, or 'none')". When the user picks, handle each picked finding through the reusable-dev skill workflow steps 2–5.
````

- [ ] **Step 4: Run case 10 (GREEN)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case 10-audit-reports-without-editing`
Expected: with-plugin arm 1.00. If the slash command text is not expanded in eval prompts (trace shows the literal `/reusable-dev:reuse-audit src` being treated as plain text with no command content), change the prompt to `Run the reusable-dev reuse-audit command on src.` and record this in the commit body.

- [ ] **Step 5: Commit**

```bash
git add agents/duplicate-finder.md commands/reuse-audit.md evals/10-audit-reports-without-editing
git commit -m "feat: add duplicate-finder agent and reuse-audit command"
```

---

### Task 10: /reuse-setup command

**Files:**
- Create: `commands/reuse-setup.md`
- Create: `evals/11-setup-writes-config/{case.yaml,setup.sh}` (fixture `react-shadcn --no-config`)

**Interfaces:**
- Consumes: `config-format.md` detection table and schema, `integration.md` extension points, `stacks/_template.md`.
- Produces: `.claude/reusable-dev.md` in the target project.

- [ ] **Step 1: Write case 11 (RED)**

`evals/11-setup-writes-config/case.yaml`
```yaml
schema_version: "1.0"
name: 11-setup-writes-config
description: /reuse-setup detects stack and ui-lib and writes the config file.
tags: [command]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-setup  (non-interactive: accept all detected defaults, leave unknown extension points empty)"
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Bash, Write, Edit]
graders:
  - type: file_exists
    name: config-created
    path: .claude/reusable-dev.md
  - type: regex
    name: stack-detected
    target: { source: file, path: .claude/reusable-dev.md }
    pattern: "stack:\\s*react-next"
  - type: regex
    name: ui-lib-detected
    target: { source: file, path: .claude/reusable-dev.md }
    pattern: "ui_lib:\\s*shadcn-react"
  - type: regex
    name: all-extension-points-present
    target: { source: file, path: .claude/reusable-dev.md }
    pattern: "design:[\\s\\S]*test:[\\s\\S]*verify:[\\s\\S]*debug:[\\s\\S]*review:[\\s\\S]*plan:[\\s\\S]*e2e:"
```

Run the case; expected FAIL.

- [ ] **Step 2: Write `commands/reuse-setup.md`**

````markdown
---
description: Detect the project's stack, UI library, commands, and optional extension skills, then write .claude/reusable-dev.md
argument-hint: "[--reset]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "AskUserQuestion"]
---

# Reuse setup

Arguments: "$ARGUMENTS"

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md`.
2. Detect every key using its detection table (read package.json, lockfiles, framework config files, components.json, tsconfig, go.mod/pyproject.toml/composer.json).
3. Extension points: read `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/integration.md`. For each point, list skills from YOUR available-skills list whose purpose matches the point (the example column is a hint, not a requirement). Only suggest skills that are actually available.
4. Stack reference: if the detected stack has no `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/stacks/<stack>.md`, offer to write one into the project at `.claude/reusable-dev/stacks/<stack>.md` from `stacks/_template.md`.
5. Ask ONE AskUserQuestion round (max 4 questions) covering: undetected keys, extension-point choices (multi-select per point group), stack file offer. If AskUserQuestion is unavailable or the arguments say non-interactive, take detected values and leave extension points `[]`.
6. Existing `.claude/reusable-dev.md` and no `--reset`: show a diff of the proposed changes and keep the existing body text; `--reset`: overwrite.
7. Write the file with every key from the schema, including all seven `skills` points.
8. Registry: if the `registry` file does not exist, ask whether to create it now by running `/reusable-dev:reuse-registry --sync` (non-interactive: create the empty template from `registry-format.md`).
9. Print the final config and the next step: "reusable-dev will now run automatically when you create or change components and functions."
````

- [ ] **Step 3: Run case 11 (GREEN)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case 11-setup-writes-config`
Expected: with-plugin arm 1.00.

- [ ] **Step 4: Commit**

```bash
git add commands/reuse-setup.md evals/11-setup-writes-config
git commit -m "feat: add reuse-setup command"
```

---

### Task 11: /reuse-registry and /reuse-verify commands

**Files:**
- Create: `commands/reuse-registry.md`
- Create: `commands/reuse-verify.md`
- Create: `evals/12-registry-sync/{case.yaml,setup.sh}` (fixture `react-shadcn`, then adds a shared file — Step 1)
- Create: `evals/13-verify-reports-skipped/{case.yaml,setup.sh}` (fixture `react-shadcn`)

**Interfaces:**
- Consumes: `registry-format.md`, `verification.md`, `shadcn-core.md` S5.

- [ ] **Step 1: Write case 12 (RED)**

`evals/12-registry-sync/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" react-shadcn
mkdir -p src/shared/lib
cat > src/shared/lib/format-date.ts <<'EOF'
export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}
EOF
```

`evals/12-registry-sync/case.yaml`
```yaml
schema_version: "1.0"
name: 12-registry-sync
description: /reuse-registry --sync adds rows for unregistered shared exports.
tags: [command]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-registry --sync  (non-interactive: apply the diff)"
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Bash, Write, Edit]
graders:
  - type: regex
    name: format-date-row
    target: { source: file, path: docs/reuse-registry.md }
    pattern: "\\|\\s*formatDate\\s*\\|\\s*src/shared/lib/format-date\\.ts"
  - type: regex
    name: in-functions-section
    target: { source: file, path: docs/reuse-registry.md }
    pattern: "## Functions · Domain[\\s\\S]*formatDate"
  - type: regex
    name: datatable-kept
    target: { source: file, path: docs/reuse-registry.md }
    pattern: "\\|\\s*DataTable\\s*\\|"
```

- [ ] **Step 2: Write case 13 (RED)**

`evals/13-verify-reports-skipped/case.yaml` (setup: fixture `react-shadcn`)
```yaml
schema_version: "1.0"
name: 13-verify-reports-skipped
description: /reuse-verify with no configured commands reports every tier as skipped, never as passed.
tags: [command]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-verify"
  max_turns: 20
  allowed_tools: [Read, Glob, Grep, Bash]
graders:
  - type: regex
    name: t1-skipped
    pattern: "T1[^\\n]*skipped"
    flags: i
  - type: regex
    name: t4-skipped
    pattern: "T4[^\\n]*skipped"
    flags: i
  - type: regex
    name: no-false-pass
    pattern: "T[1-4][^\\n]*✓"
    match: not_contains
```

Run both cases; expected FAIL.

- [ ] **Step 3: Write `commands/reuse-registry.md`**

````markdown
---
description: Sync docs/reuse-registry.md with the exports in shared paths; optionally generate a shadcn registry.json
argument-hint: "[--sync] [--shadcn-registry]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "AskUserQuestion"]
---

# Reuse registry

Arguments: "$ARGUMENTS"

1. Read `.claude/reusable-dev.md` (missing → detection from `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/config-format.md`, not saved) and `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/registry-format.md`.
2. Collect exports: under `shared_paths.components`, `shared_paths.functions`, the ui-lib primitives dir, and any `hooks`/`composables` dirs next to them. Skip test files and index/barrel files (register the real file).
3. For each export compute Name, Path, Purpose (from its doc comment or by reading the body — one line), API (props/params), Used by (grep import sites outside its file and tests), Notes.
4. Compare with the registry: `add` (export not in registry), `update` (API or Used by changed), `remove` (row path missing). Without `--sync`: print the diff table and stop. With `--sync`: show the diff, ask for confirmation once (non-interactive: apply), then write, keeping section order and alphabetical rows.
5. `--shadcn-registry` and `ui_lib` starts with `shadcn`: generate `registry.json` at repo root following the researched schema in `ui-libs/shadcn-core.md` (rule S5), one item per shared pattern component, and print the command teammates use to add an item.
6. Report counts: `added N · updated N · removed N`.
````

- [ ] **Step 4: Write `commands/reuse-verify.md`**

````markdown
---
description: Run the full verification ladder T1–T4 for current changes and report real results
argument-hint: "[path or 'all']"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Skill"]
---

# Reuse verify

Scope: "$ARGUMENTS" (empty → files changed vs `HEAD` per `git status --porcelain`; not a git repo → `all`)

1. Read `.claude/reusable-dev.md` and `${CLAUDE_PLUGIN_ROOT}/skills/reusable-dev/references/verification.md`.
2. T1: run each non-empty `commands.typecheck`, `commands.lint`, `commands.build`. Empty → `skipped (no command)`.
3. T2: run `commands.test` for the scope. Empty → `skipped (no command)`.
4. T3: for each changed shared unit in scope, find call sites and run their tests per verification.md. No changed shared units → `skipped (no shared changes)`.
5. T4: extension point `e2e` skills (invoke in order) or `commands.e2e`. Neither → `skipped (no e2e configured)`.
6. On any failure: stop the ladder, apply extension point `debug` (fallback in verification.md), and report the failure — do not continue to later tiers.
7. Output exactly:
```
Verified: T1 … · T2 … · T3 … · T4 …
Notes: …
```
Never print ✓ for a tier whose command did not run.
````

- [ ] **Step 5: Run cases 12 and 13 (GREEN)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case "1[23]-*"`
Expected: with-plugin arm 1.00 for both.

- [ ] **Step 6: Commit**

```bash
git add commands/reuse-registry.md commands/reuse-verify.md evals/12-registry-sync evals/13-verify-reports-skipped
git commit -m "feat: add reuse-registry and reuse-verify commands"
```

---

### Task 12: Planning integration eval + manual superpowers checklist

**Files:**
- Create: `evals/06-plan-has-reuse-decisions/{case.yaml,setup.sh}` (fixture `react-shadcn`)
- Create: `evals/MANUAL.md`

**Interfaces:**
- Consumes: SKILL.md "When planning instead of coding", integration.md requirements table.

- [ ] **Step 1: Write case 06**

`evals/06-plan-has-reuse-decisions/case.yaml`
```yaml
schema_version: "1.0"
name: 06-plan-has-reuse-decisions
description: An implementation plan includes a Reuse decision line for each code task.
tags: [behavior, plan]
context:
  scaffold_script: setup.sh
execution:
  prompt: "Don't write code yet. Write an implementation plan to docs/plan.md for adding a customers list page with a table of customers (name, email, signup date) and a Delete button per row. Break it into numbered tasks."
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Write, Skill]
graders:
  - type: file_exists
    name: plan-written
    path: docs/plan.md
  - type: regex
    name: has-reuse-decisions
    target: { source: file, path: docs/plan.md }
    pattern: "(Reuse decision:[\\s\\S]*){3}"
  - type: llm
    name: decisions-name-existing-units
    criteria: "docs/plan.md reuses DataTable (src/shared/ui/DataTable.tsx) for the table, extends Button with a destructive/danger variant for Delete, and extracts formatDate to shared for the signup date. Each of these appears in a 'Reuse decision:' line."
    focus: { source: file, path: docs/plan.md }
```

The `has-reuse-decisions` pattern requires at least three `Reuse decision:` lines (one per code task: table, delete button, signup date).

- [ ] **Step 2: Run case 06**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --runs 1 --case 06-plan-has-reuse-decisions`
Expected: with-plugin arm 1.00.

- [ ] **Step 3: Write `evals/MANUAL.md`**

````markdown
# Manual checks — reusable-dev with superpowers installed

`claude plugin eval` cannot load plugins from outside this repo, so co-operation with superpowers is checked by hand before each release.

Setup: a scratch copy of `evals/fixtures/react-shadcn`, superpowers installed and enabled, then start `claude --plugin-dir /Users/ekayut/Project/ai/claude-skill` in that copy.

| # | Do | Pass when |
|---|---|---|
| M1 | "/superpowers:brainstorming add a customers list page with delete per row" → approve through to the plan | Design mentions DataTable reuse and Button extend; every code task in the written plan has a `Reuse decision:` line |
| M2 | Execute the plan with superpowers:subagent-driven-development | No new Button/Table component files; implementer prompts contain the `Reuse decision:` lines |
| M3 | During M2, observe TDD | reusable-dev does not invoke test-driven-development a second time; shared Button test covers the new variant |
| M4 | Before completion | Verification output includes T3 call sites for Button |
| M5 | Uninstall/disable superpowers and repeat M1 without brainstorming ("plan a customers page") | Plan still has `Reuse decision:` lines; no errors about missing skills |

Record date, Claude Code version, superpowers version, and pass/fail per row at the bottom of this file.
````

- [ ] **Step 4: Commit**

```bash
git add evals/06-plan-has-reuse-decisions evals/MANUAL.md
git commit -m "test: add planning integration eval and manual superpowers checklist"
```

---

### Task 13: Structural review and full eval acceptance

**Files:**
- Modify (only per findings): any plugin file

- [ ] **Step 1: Validate strictly**

Run: `claude plugin validate . --strict`
Expected: exit 0, no warnings.

- [ ] **Step 2: Plugin structure review**

Dispatch agent `plugin-dev:plugin-validator` with prompt: "Validate the Claude Code plugin at /Users/ekayut/Project/ai/claude-skill (manifest, skills, commands, agents). Report errors and warnings only."
Fix every error; fix warnings unless they contradict Global Constraints.

- [ ] **Step 3: Skill review**

Dispatch agent `plugin-dev:skill-reviewer` with prompt: "Review skills/reusable-dev/SKILL.md and its references in /Users/ekayut/Project/ai/claude-skill for trigger quality of the description, progressive disclosure, and clarity. Constraints that must stay: SKILL.md body ≤ 120 lines, references ≤ 150 lines, decision ladder Reuse → Extend → Compose → Create, tiers T1–T4, seven extension points, report prefixes 'Reuse decision:', 'Verified:', 'Notes:'."
Apply findings that do not break the listed constraints.

- [ ] **Step 4: Token cost check**

Run: `claude plugin details .`
Expected: the always-loaded cost is only the skill description + command/agent descriptions (references not listed as always-loaded). Record the numbers in the commit body.

- [ ] **Step 5: Full acceptance run (3 runs per case)**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish --json evals/results/acceptance.json`
Expected: every case with-plugin score ≥ 0.9 (default threshold 1.0 may flag single flaky runs — inspect any case below 1.0 and fix real failures); ablation delta positive for cases 01–05 and 06. Case 00 is harness-only and 09 must stay 1.00.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: pass plugin validation, skill review, and full eval acceptance"
```

---

### Task 14: README and local install

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write the full `README.md`**

````markdown
# reusable-dev

Claude Code plugin สำหรับพัฒนาระบบแบบ **reuse-first**: หา component/function เดิมก่อนสร้างใหม่ · ออกแบบให้ reuse ได้ · มีทะเบียน · ตรวจสอบรวมถึงจุดที่เรียกใช้

Reuse-first development for Claude Code. Stack-agnostic, works alone or alongside other skill plugins.

## ทำงานอย่างไร / How it works

เมื่อ Claude กำลังสร้างหรือแก้ component, hook/composable, function, service skill `reusable-dev` จะทำงานอัตโนมัติ:

```
0. Load config → 1. Discover → 2. Decide → 3. Design → 4. Verify → 5. Register
```

- **Decide:** Reuse → Extend → Compose → Create (Rule of Three ก่อนย้ายขึ้น shared)
- **Verify:** T1 typecheck/lint/build · T2 unit tests · T3 call-site tests · T4 e2e (สั่งเอง)
- จบงานด้วยรายงาน `Reuse decision:` / `Verified:` / `Notes:`

## Commands

| Command | ใช้ทำอะไร |
|---|---|
| `/reusable-dev:reuse-setup` | ตรวจ stack/ui-lib/คำสั่ง + เลือก extension skills → เขียน `.claude/reusable-dev.md` |
| `/reusable-dev:reuse-audit [path]` | หาโค้ดซ้ำและจุดผิดกฎ เรียงตามผลกระทบ (ไม่แก้ไฟล์เอง) |
| `/reusable-dev:reuse-registry [--sync] [--shadcn-registry]` | sync `docs/reuse-registry.md` กับโค้ดจริง |
| `/reusable-dev:reuse-verify [path]` | ตรวจครบ T1–T4 |

## รองรับ / Supported (phase 1)

Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript
UI libraries: shadcn/ui · shadcn-vue · shadcn-svelte
Stack อื่นใช้หลักการทั่วไปได้ และ `/reusable-dev:reuse-setup` สร้างไฟล์ stack ใหม่จาก template ได้

## Extension points

ไม่บังคับ plugin อื่น แต่เสียบ skill ที่มีอยู่ได้ใน `.claude/reusable-dev.md`:
`design` · `test` · `verify` · `debug` · `review` · `plan` · `e2e`
เช่น `test: [superpowers:test-driven-development]` — ถ้าไม่ได้ติดตั้ง จะใช้ built-in fallback และแจ้งใน Notes

ใช้คู่กับ superpowers: superpowers คุมกระบวนการตามปกติ ส่วน reusable-dev เติมเรื่อง reuse (เช่น `Reuse decision:` ในทุก task ของ plan)

## ติดตั้ง / Install

ทดลองในเครื่อง:
```bash
claude --plugin-dir /path/to/claude-skill
```

ผ่าน marketplace: เพิ่ม entry ใน `.claude-plugin/marketplace.json` ของ marketplace ที่ใช้ แล้ว
```bash
claude plugin install reusable-dev@<marketplace>
```

## พัฒนา / Development

```bash
claude plugin validate . --strict
claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit --judge-model sonnet --no-publish
```
Manual checks with superpowers: `evals/MANUAL.md`
````

- [ ] **Step 2: Local smoke test**

Run in a scratch copy:
```bash
S=$(mktemp -d) && cp -R evals/fixtures/node-ts/. "$S" && cd "$S" && claude --plugin-dir /Users/ekayut/Project/ai/claude-skill -p "Add a shared function percentOf(part: number, whole: number): number next to formatCurrency with a test" --allowedTools "Read,Glob,Grep,Edit,Write,Bash,Skill"; cd -
```
Expected: output ends with `Reuse decision:` and `Verified:` lines showing T2 test counts from `node --test`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README with usage, commands, and install"
```

- [ ] **Step 4: Ask the user about distribution**

Ask whether to add `reusable-dev` to the existing local marketplace at `/Users/ekayut/Project/ekayutdev-plugins` (it uses `"source": "./plugins/<name>"`, so this means copying or symlinking the plugin there and adding an entry). Do not modify that repo without a yes.
