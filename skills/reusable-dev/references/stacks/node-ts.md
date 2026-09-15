<!-- researched 2026-09-14: node@24 LTS (v24.21.0), typescript@7.0.2, vitest@5.0.0 (nodejs.org/api/test, typescriptlang.org, vitest.dev) -->
# Stack: node-ts

Node.js + TypeScript backend (no UI framework; server framework optional).

## Detection
`tsconfig.json` plus a server framework (`express`, `fastify`, `hono`) in deps, or no UI framework at all. (NestJS projects use `stacks/nestjs.md`)

## Reuse units
- Pure function/domain: one module per domain area, `src/domain/money.ts`, `src/domain/invoiceTotals.ts` (verb + noun exports).
- Service (orchestrates IO): `src/services/invoiceService.ts` — a factory function returning an object of methods.
- Handler/adapter: `src/http/invoiceRoutes.ts` (or `src/routes/`, `src/jobs/`) — thin wrappers that parse input and call services.

## Paths
- `src/domain` (pure, no IO) → `src/services` (IO orchestration) → `src/http|routes|jobs` (adapters).
- Domain may import only from domain. Services import domain plus injected clients. Handlers import services.
- Code shared by web + api goes in a workspace package `packages/shared` (npm workspaces), never duplicated per app.

## Component idioms
Not applicable — no UI. C3–C6 (variant enums, children/slots, rest props/ref, controlled inputs) have no node-ts equivalent; apply component-design.md only where a UI stack exists in the same monorepo.

## Logic idioms
- F2 DI: factory functions taking a `deps` object — clients, clock, and randomness arrive as arguments; no module-level singletons created at import time.
```ts
export interface InvoiceDeps { db: Db; clock: () => Date }
export function createInvoiceService(deps: InvoiceDeps) {
  return {
    async getInvoice(id: string): Promise<Invoice> {
      const invoice = await deps.db.findInvoice(id);
      if (!invoice) throw new NotFoundError(id);   // F6 throw style
      return invoice;
    },
  };
}
```
```ts
// F6 result style (alternative — pick ONE per config error_style, never mix)
export type Result<T, E> =
  | { ok: true; value: T }
  | { ok: false; error: E };
export class NotFoundError extends Error {
  constructor(id: string) { super(`resource ${id} not found`); }
}
```

## Testing
- Vitest (preferred): one file `npx vitest run src/domain/money.test.ts` (substring filter also works; `vitest run` = no watch). Default suite: `vitest run`.
- Node built-in runner (zero deps): `node --test` runs `**/*.test.{cjs,mjs,js,ts}`; one file: `node --test src/domain/money.test.ts` (nodejs.org/api/test). Caveat: `node --test file.ts` supports only erasable TypeScript syntax — no enums, parameter properties, or namespaces with runtime code (`ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX`), and imports need explicit `.ts` extensions (nodejs.org/api/typescript). If the code uses those features, run tests via `commands.test` instead (e.g. Vitest).

## Stack-specific anti-patterns
- Services importing HTTP request/response objects — parse in the handler, pass plain data.
- Singletons created at import time — inject via a `deps` object or factory instead.
- A catch-all `utils.ts` dumping ground — group by domain (`money.ts`, `dates.ts`).
- Boolean flags that switch a function's whole behavior — split into two functions (F5).
- Duplicating domain logic between apps instead of `packages/shared`.
