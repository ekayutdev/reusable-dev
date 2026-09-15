<!-- researched 2026-09-15: @nestjs/core@12.0.2 current docs, v11 pages where newer ones restructured (docs.nestjs.com/modules, /fundamentals/custom-providers, /fundamentals/testing, /cli/monorepo); node@26.7.0 -->
Read node-ts.md first.

# Stack: nestjs

NestJS backend. node-ts.md applies except Reuse units, Paths, and F2 (dependency injection) below, which replace it.

## Detection
`@nestjs/core` in `package.json` dependencies, or a `nest-cli.json` present (detection row 11).

## Reuse units
- Shareable module: a `@Module` class whose `exports` array is its public API — any module importing it gets the same singleton provider instances (docs.nestjs.com/modules, "Shared modules").
- Provider: an `@Injectable()` class in a feature module's `providers` — services, repositories, helpers, factories.
- Cross-cutting concern: pipes, guards, interceptors, and custom decorators — reusable behaviors attached per-route or globally, one per concern.
- Pure domain function: a plain exported function with no decorators (see Logic idioms).

## Paths
- `src/<feature>/` per feature: `<feature>.module.ts`, `<feature>.controller.ts`, `<feature>.service.ts` (module, controller, service together).
- `src/common/` for shared helpers, providers, pipes, guards, interceptors used by several features (per config `shared_paths.functions`).
- Nest monorepo mode: cross-app reusable code lives in `libs/` as a library project (`nest generate library`), imported by path alias (docs.nestjs.com/cli/monorepo).

## Component idioms
Not applicable — no UI. C3–C6 have no NestJS equivalent; apply component-design.md only where a UI stack exists in the same monorepo.

## Logic idioms
- F2 DI: constructor injection — declare dependencies in the constructor; the Nest IoC container wires and caches singletons per module graph.
```ts
import { Injectable } from "@nestjs/common";

@Injectable()
export class ReportsService {
  constructor(private readonly accounts: AccountsService) {}   // injected, no manual instantiation
}
```
- Injection tokens for interfaces/non-class dependencies (docs.nestjs.com/fundamentals/custom-providers):
```ts
import { Inject, Injectable } from "@nestjs/common";

export const REPORTS_CLOCK = Symbol("REPORTS_CLOCK");

@Injectable()
export class ReportsService {
  constructor(@Inject(REPORTS_CLOCK) private readonly clock: () => Date) {}
}
// provider: { provide: REPORTS_CLOCK, useValue: () => new Date() }
```
- Keep domain logic in plain exported functions without decorators (node-ts.md domain rules) so they are testable without bootstrapping Nest; controllers stay thin adapters and services orchestrate.
- F6: Domain errors stay framework-free; map them to `HttpException` subclasses in an exception filter or the controller, never in services.

## Testing
- Providers: `Test.createTestingModule({ controllers: [...], providers: [...] })` from `@nestjs/testing`, then `.overrideProvider(X).useValue(mock)` and `.compile()`; get instances via `moduleRef.get(X)` (docs.nestjs.com/fundamentals/testing).
- Pure functions: the project's runner — `jest <path>`, `vitest run <path>`, or `node --test <path>` — no Nest involved. Use exactly what config `commands.test` says.
- Decorators and constructor parameter properties are not erasable TypeScript — code under `node --test` must not import decorated files; test providers with Jest or Vitest (with SWC).

## Stack-specific anti-patterns
- Business logic in controllers — controllers parse and delegate to a provider; logic there is a copy no queue/CLI consumer can reuse.
- Circular module imports — `forwardRef` is a smell, not a fix (docs.nestjs.com/fundamentals/circular-dependency); extract the shared part instead.
- A `@Global()` module exporting everything — the docs warn against making everything global; import modules explicitly so each dependency is visible.
- Unnecessary request-scoped providers — default singleton scope is cheaper; request scope has real cost (docs.nestjs.com/fundamentals/injection-scopes).
- Duplicated helpers across feature modules instead of one `src/common/` module or a `libs/` library.
