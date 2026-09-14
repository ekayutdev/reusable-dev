<!-- researched 2026-09-14: svelte@5.57.0, @sveltejs/kit@2.70.3, vitest@5.0.0, @testing-library/svelte@5.4.2 (svelte.dev/docs, vitest.dev) -->
# Stack: sveltekit

SvelteKit 2 + Svelte 5 runes.

## Detection
`svelte.config.*`, or `"@sveltejs/kit"` in package.json deps.

## Reuse units
- UI component: `src/lib/components/Button.svelte` (PascalCase).
- Stateful logic: runes module `src/lib/cart.svelte.ts` / `useDebouncedValue.svelte.ts` — `.svelte.ts` files may use `$state`, `$derived`, `$effect` (svelte.dev/docs, svelte-js-files). Name by domain, never a catch-all `utils.*` (F8).
- Pure function/domain: plain `.ts` module `src/lib/money.ts` (no runes needed).

## Paths
- Primitives/patterns: `src/lib/components`; domain functions/services: `src/lib`; stateful logic: `.svelte.ts` runes modules in `src/lib`.
- Server-only code: `src/lib/server` — importable only via `$lib/server`; SvelteKit prevents importing it from client code (svelte.dev/docs/kit, project-structure). Components never import `$lib/server`.
- Data loading: in `+page.server.ts` / `+layout.server.ts` `load` functions (or `+page.ts` for universal load), not in components.

## Component idioms
```svelte
<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLButtonAttributes } from 'svelte/elements';
  // C3 variant enum + C6 bindable + C4 children snippet + C5 rest props + ref
  interface Props extends HTMLButtonAttributes {
    variant?: 'default' | 'destructive';
    size?: 'sm' | 'md';
    children?: Snippet;              // C4: implicit children snippet
    ref?: HTMLButtonElement | null;  // C5: bindable ref to the root element
  }
  let { ref = $bindable(null), variant = 'default', size = 'md', children, ...rest }: Props = $props();
</script>

<button bind:this={ref} {...rest} data-variant={variant}>  <!-- C5 -->
  {@render children?.()}                                  <!-- C4 -->
</button>
```
- C5: Svelte has NO attribute fallthrough — attributes reach an element only through an explicit rest spread. Extend `Props` from `HTMLButtonAttributes` (svelte/elements) so `...rest` accepts native attributes (svelte.dev/docs/svelte/typescript). C5 ref: the bindable `ref` pattern above forwards the root DOM element — parent writes `<Button bind:ref={el}>`. Secondary: `bind:this` on a component gives its instance — exported functions from `<script>` (instance exports, `export function empty() {}`) are callable on that ref (svelte.dev/docs/svelte/bind).
- C6: controlled = parent binds `bind:value` to a `$bindable()` prop; uncontrolled = parent passes a plain prop, the `$bindable()` fallback value acts as the default. There is no separate default-value prop — use the `$bindable()` fallback.
- C4: snippets replace slots — `{#snippet name(arg)}…{/snippet}` passed as props, `{@render children?.()}` to render; implicit `children` snippet covers the old default slot.

## Logic idioms
- F2: `load` functions and services receive IO (db, fetch) as parameters; `src/lib` pure functions take data, not clients.
```ts
// F6 throw style
export class NotFoundError extends Error {
  constructor(id: string) { super(`resource ${id} not found`); }
}
```
- F6 result style (`error_style: result`): return `{ ok: true, value } | { ok: false, error }` — pick ONE per config error_style, never mix.

## Testing
- Vitest + `@testing-library/svelte` (`render`, `screen`); `userEvent` from `@testing-library/user-event`.
- Tests that use runes must have `.svelte` in the filename (e.g. `counter.svelte.test.ts`) — Vitest then processes them like source files (svelte.dev/docs/svelte/testing). Component tests need a DOM environment — `environment: 'jsdom'` in the Vitest config (or a `// @vitest-environment jsdom` file comment) — and `resolve.conditions: ['browser']` so packages resolve their browser entry points.
- One file, either kind: `npx vitest run counter.svelte.test.ts` / `npx vitest run Button.test.ts` (substring filter also works; `vitest run` = no watch).

## Stack-specific anti-patterns
- Stores for local state in Svelte 5 code — use `$state`/`$derived` runes; shared reactive state can be `$state` in a `.svelte.ts` module; stores remain for async streams/manual subscription control.
- Fetching in components — use `load` in `+page.server.ts`/`+page.ts`.
- Importing `$lib/server` from client code — it is server-only by design.
- Old `on:click`/`slot` syntax in new components — Svelte 5 uses `onclick=` and snippets.
- Duplicating domain logic in `.svelte.ts` files when plain `.ts` is enough — runes are for state, not for purity theater.
