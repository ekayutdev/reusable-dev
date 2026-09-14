<!-- researched 2026-09-14: svelte@5.57.0, @sveltejs/kit@2.70.3, vitest@5.0.0, @testing-library/svelte@5.4.2 (svelte.dev/docs, vitest.dev) -->
# Stack: sveltekit

SvelteKit 2 + Svelte 5 runes.

## Detection
`svelte.config.*`, or `"@sveltejs/kit"` in package.json deps.

## Reuse units
- UI component: `src/lib/components/Button.svelte` (PascalCase).
- Stateful logic: runes module `src/lib/utils.svelte.ts` / `useDebouncedValue.svelte.ts` — `.svelte.ts` files may use `$state`, `$derived`, `$effect` (svelte.dev/docs, svelte-js-files).
- Pure function/domain: plain `.ts` module `src/lib/money.ts` (no runes needed).

## Paths
- Primitives/patterns: `src/lib/components`; domain functions/services: `src/lib`; stateful logic: `.svelte.ts` runes modules in `src/lib`.
- Server-only code: `src/lib/server` — importable only via `$lib/server`; SvelteKit prevents importing it from client code (svelte.dev/docs/kit, project-structure). Components never import `$lib/server`.
- Data loading: in `+page.server.ts` / `+layout.server.ts` `load` functions (or `+page.ts` for universal load), not in components.

## Component idioms
```svelte
<script lang="ts">
  import type { Snippet } from 'svelte';
  // C3 variant enum + C6 bindable + C4 children snippet + C5 rest props
  interface Props {
    variant?: 'default' | 'destructive';
    size?: 'sm' | 'md';
    children?: Snippet;              // C4: implicit children snippet
    value?: string;                  // C6: parent may bind value or pass plain prop
  }
  let { variant = 'default', size = 'md', children, value = $bindable(''), ...props }: Props = $props();
</script>

<button data-variant={variant} {...props}>  <!-- C5: rest props spread to root -->
  {@render children?.()}                     <!-- C4 -->
</button>
```
- C5: spread unknown attrs with `{...props}` on the root element (no automatic fallthrough in Svelte 5 when you use rest props; use rest props in every wrapper). Ref/instance: `bind:this={ref}` on the component; exported functions from `<script>` (instance exports) are callable on that ref (`export function empty() {}` — svelte.dev/docs/svelte/bind).
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

## Testing
- Vitest + `@testing-library/svelte` (`render`, `screen`).
- One file: `npx vitest run path/to/file.test.ts` (substring filter also works; `vitest run` = no watch).

## Stack-specific anti-patterns
- Stores for local state in Svelte 5 code — use `$state`/`$derived` runes; stores are for cross-app state only.
- Fetching in components — use `load` in `+page.server.ts`/`+page.ts`.
- Importing `$lib/server` from client code — it is server-only by design.
- Old `on:click`/`slot` syntax in new components — Svelte 5 uses `onclick=` and snippets.
- Duplicating domain logic in `.svelte.ts` files when plain `.ts` is enough — runes are for state, not for purity theater.
