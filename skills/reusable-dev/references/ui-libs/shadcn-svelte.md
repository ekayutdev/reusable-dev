<!-- researched 2026-09-14: shadcn@4.21.0 (React, ui.shadcn.com/docs), shadcn-vue@2.8.2 + reka-ui@2.10.4 (shadcn-vue.com/docs, unovue/shadcn-vue dev registry), shadcn-svelte@1.6.1 + bits-ui@2.19.2 + tailwind-variants@3.3.1 (shadcn-svelte.com/docs, huntabyte/shadcn-svelte main), class-variance-authority@0.7.1, clsx@2.1.1, tailwind-merge@3.3.0 (npm registry) -->
Read shadcn-core.md first.

# UI library: shadcn-svelte

## Detection
`components.json` with `$schema` `https://shadcn-svelte.com/schema.json`, or `"@sveltejs/kit"` in package.json deps plus the `cn` util at `aliases.utils` (`$lib/utils`).

## Primitives location
`aliases.ui` in `components.json` — default `$lib/components/ui`, one folder per primitive: `components/ui/button/button.svelte` (Svelte 5 runes component; the `tailwind-variants` (`tv`) variants definition lives in its `<script module>` — variants are exported from the component file, `index.ts` re-exports) + `components/ui/button/index.ts`. Primitives build on Bits UI and style with `tailwind-variants` + `cn` (S4). Import from `$lib/components/ui/button/index.js`.

## Adding a primitive (CLI)
`pnpm dlx shadcn-svelte@latest add <name>` (or `npx`/`bunx`); supports URLs and local paths. `npx shadcn-svelte@latest init` creates `components.json` when absent.

## Customizing without forking (S2 example: destructive Button variant)
```svelte
<!-- components/ui/button/button.svelte — module script; call sites unchanged -->
<script lang="ts" module>
  export const buttonVariants = tv({
    base: "...",
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/80",
        destructive: "bg-destructive text-white hover:bg-destructive/90", // added
      },
    },
    defaultVariants: { variant: "default" },
  });
</script>
```
Behavior/composition → wrap in the patterns layer (`shared_paths.components`), never in `components/ui`:
```svelte
<!-- src/lib/components/shared/ConfirmButton.svelte -->
<script lang="ts">
  import { Button } from "$lib/components/ui/button/index.js";
  let { children, ...rest } = $props();
</script>
<Button variant="destructive" {...rest}>{@render children?.()}</Button>
```

## Cross-project sharing
Build a registry with `shadcn-svelte@latest registry build` from a `registry.json` (writes to `static/r`), served via the `registry` URL in `components.json` so other projects `add` from it. Shared components follow S5.

## Anti-patterns
- Hand-writing a primitive the registry has (S1) — `shadcn-svelte add` it instead.
- Putting your own components in `components/ui` — that dir is the primitives layer.
- Hex color literals in variants (S4) — use CSS variables (`bg-primary`, `text-destructive`).
- `on:click`/slots syntax in primitives — Svelte 5 uses `onclick=` and snippets.
- Editing a generated file beyond a variant without a `shadcn modified:` registry note (S3).
