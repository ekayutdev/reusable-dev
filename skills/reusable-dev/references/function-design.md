# Function and service design rules

Principles → checkable rules → anti-patterns → example.

## Layers

`lib/domain` (pure) → `services` (orchestrate IO) → `handlers/adapters` (HTTP, CLI, jobs, UI actions).
Pure code never imports services or adapters. When frontend and backend share a language, domain code shared by both lives in a shared package (`packages/shared`), not duplicated.

## Rules

| ID | Rule | How to check |
|---|---|---|
| F1 | Business logic is a pure function: same input → same output, no IO, no clock, no randomness. | no `fetch`, db client, `Date.now()`, `Math.random()` in `lib/domain` files |
| F2 | IO dependencies (db, http, clock, randomness) are parameters or constructor args, not imports inside logic. | no db/http client imports in domain or service logic except type-only imports; services receive clients as arguments |
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

// ✓ After: pure core + injected IO + options object; the flag becomes two functions
export function summarizeRows(rows: Row[]): Summary { … }
export function summarizeRowsWithTax(rows: Row[], taxRate: number): Summary { … }
export async function buildReport(
  deps: { db: Db },
  q: { userId: string; from: Date; to: Date; format: ReportFormat },
): Promise<Report> {
  return renderReport(summarizeRows(await deps.db.rows(q)), q.format);
}
```
