<!-- researched 2026-09-14: shadcn@4.21.0 (React, ui.shadcn.com/docs), shadcn-vue@2.8.2 + reka-ui@2.10.4 (shadcn-vue.com/docs, unovue/shadcn-vue dev registry), shadcn-svelte@1.6.1 + bits-ui@2.19.2 + tailwind-variants@3.3.1 (shadcn-svelte.com/docs, huntabyte/shadcn-svelte main), class-variance-authority@0.7.1, clsx@2.1.1, tailwind-merge@3.3.0 (npm registry) -->
Read shadcn-core.md first.

# UI library: shadcn-vue

## Detection
`components.json` with `$schema` `https://shadcn-vue.com/schema.json`, or `"vue"` in package.json deps plus the `cn` util at the `aliases.utils` path.

## Primitives location
`aliases.ui` in `components.json` — default `@/components/ui`, one folder per primitive: `components/ui/button/index.ts` (exports the component and its `cva` variants definition) + `components/ui/button/Button.vue` (the component). Primitives build on Reka UI (unovue) and style with `cva` + `cn` (S4).

## Adding a primitive (CLI)
`pnpm dlx shadcn-vue@latest add <name>` (or `npx`/`bunx`); supports URLs and registry items. `npx shadcn-vue@latest init` creates `components.json` when absent.

## Customizing without forking (S2 example: destructive Button variant)
```ts
// components/ui/button/index.ts — variants live here; call sites unchanged
const buttonVariants = cva(base, {
  variants: {
    variant: {
      default: "bg-primary text-primary-foreground hover:bg-primary/90",
      destructive: "bg-destructive text-white hover:bg-destructive/90", // added
    },
  },
});
```
Behavior/composition → wrap in the patterns layer (`shared_paths.components`), never in `components/ui`:
```vue
<!-- src/components/shared/ConfirmButton.vue -->
<script setup lang="ts">
import { Button } from "@/components/ui/button"
</script>
<template>
  <Button variant="destructive" v-bind="$attrs"><slot /></Button>
</template>
```

## Cross-project sharing
Build a registry with `shadcn-vue@latest build` from a `registry.json`/`registry-item.json` (same schema family as React), or copy-and-paste via the docs' manual code blocks. Shared components follow S5 — propose a private registry, don't fork primitives per project.

## Anti-patterns
- Hand-writing a primitive the registry has (S1) — `shadcn-vue add` it instead.
- Putting your own components in `components/ui` — that dir is the primitives layer.
- Hex color literals in variants (S4) — use CSS variables (`bg-primary`, `text-destructive`).
- New looks via a wrapper component instead of a variant (S2).
- Editing a generated file beyond a variant without a `shadcn modified:` registry note (S3).
