<!-- researched 2026-09-14: next@16.3.5, react@19.3.0, react-dom@19.3.0, vitest@5.0.0, @testing-library/react@16.3.3 (nextjs.org/docs, react.dev, vitest.dev) -->
# Stack: react-next

Next.js App Router + React 19.

## Detection
`next.config.*`, or `"next"` in package.json deps (detection row 1). A bare `"react"` dependency without Next also maps here (detection row 10) — the Next-only idioms below (App Router, Server Components) then do not apply.

## Reuse units
- UI component: one file per component, `src/shared/ui/Button.tsx` (PascalCase).
- Stateful logic: `use*` hook, `src/shared/hooks/useDebouncedValue.ts`.
- Pure function/domain: `src/shared/lib/money.ts` (camelCase verb + noun).

## Paths
- Primitives and patterns: `src/shared/ui` (or `components/` in src-less projects); hooks: `src/shared/hooks`; pure helpers/domain: `src/shared/lib`.
- Server vs client: every component is a Server Component by default. Mark `"use client"` at the top of the leaf file that needs interactivity (state, effects, event handlers) — never at a barrel or shared-module level. Keep shared primitives server-compatible when possible.
- Data fetching: in Server Components (async components) or route handlers (`app/**/route.ts`) — never inside shared UI (C2). Server Actions/Functions are for mutations, not data fetching (nextjs.org/docs; react.dev/reference/react/server-functions).
- Colocation: `app/` holds route segments; non-routable files colocate with `_folder` (private) or live outside `app/` (`src/shared/ui`). Use `src/` consistently or not at all.

## Component idioms
```tsx
// C3 variant enum + C4 children + C5 rest props/ref + C6 controlled input
type ButtonProps = React.ComponentPropsWithRef<'button'> & {
  variant?: 'default' | 'destructive';      // C3: enum, no isDanger boolean
  size?: 'sm' | 'md';
};
function Button({ variant = 'default', size = 'md', ...props }: ButtonProps) {
  return <button data-variant={variant} {...props} />; // C5: rest props + ref reach root
}
// <Button variant="destructive">Delete</Button>       — C4: children, no label prop
```
- C5 ref: React 19 — `ref` is a regular prop for function components; `forwardRef` is no longer needed. It is not deprecated yet: react.dev says it "will be deprecated in a future release" (react.dev/reference/react/forwardRef). Reach the root via `...props` spread.
- C6 controlled: `value` + `onChange` (`ComponentPropsWithRef<'input'>` names). Uncontrolled: `defaultValue` + `ref`. A shared input supports both — accept both props, forward what is set.
- Multi-root or wrapped-root components must spread rest props explicitly; React has no automatic attribute fallthrough.

## Logic idioms
- F2: IO (fetch/db) is injected into hooks and services as a parameter or context value, not imported inside `src/shared/lib` domain files.
```ts
// F6 throw style
export class NotFoundError extends Error {
  constructor(id: string) { super(`resource ${id} not found`); }
}
```
- F6 result style (`error_style: result`): return `{ ok: true, value } | { ok: false, error }` — pick ONE per config error_style, never mix.

## Testing
- Vitest + @testing-library/react (`render`, `screen`); `userEvent` comes from `@testing-library/user-event`.
- One file: `npx vitest run path/to/file.test.tsx` (`vitest run` = no watch; a filename substring filter also works).
- Defaults: `npm test` = `vitest run`; component tests colocate as `Button.test.tsx` or live in `__tests__/`.

## Stack-specific anti-patterns
- `useEffect` to derive state — compute during render or with `useMemo`.
- Context for everything — only for truly cross-tree state; prop drilling across ≤ 2 levels is fine.
- Barrel files that re-export `"use client"` leaves, pulling client code into server bundles.
- Data fetching inside shared UI components (C2) — fetch in Server Components or route handlers and pass data down as props.
- Adding `forwardRef` in new React 19 code — accept `ref` via props/rest instead.
