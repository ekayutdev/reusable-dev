<!-- researched 2026-09-14: shadcn@4.21.0 (React, ui.shadcn.com/docs), shadcn-vue@2.8.2 + reka-ui@2.10.4 (shadcn-vue.com/docs, unovue/shadcn-vue dev registry), shadcn-svelte@1.6.1 + bits-ui@2.19.2 + tailwind-variants@3.3.1 (shadcn-svelte.com/docs, huntabyte/shadcn-svelte main), class-variance-authority@0.7.1, clsx@2.1.1, tailwind-merge@3.3.0 (npm registry) -->
Read shadcn-core.md first.

# UI library: shadcn-react

## Detection
`components.json` with `$schema` `https://ui.shadcn.com/schema.json`, or `"react"` in package.json deps plus the `cn` util at the `aliases.utils` path.

## Primitives location
`aliases.ui` in `components.json` — default `@/components/ui`, one file per primitive (`@/components/ui/button.tsx`). Primitives build on Radix (`radix-ui` package) and style with `cva` + `cn` (S4).

## Adding a primitive (CLI)
`pnpm dlx shadcn@latest add <name>` (or `npx`/`bunx`); supports URLs, local paths, and namespaced registry items `@namespace/item`. Inspect first with `pnpm dlx shadcn@latest view <item>`; find items with `shadcn@latest search <registry> -q "<term>"` (`list` is an alias).

## Customizing without forking (S2 example: destructive Button variant)
```tsx
// components/ui/button.tsx — existing call sites unchanged
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
```tsx
// src/shared/ui/ConfirmButton.tsx — wraps Button, keeps its API
export function ConfirmButton(props: React.ComponentProps<typeof Button>) {
  return <Button variant="destructive" {...props} />;
}
```

## Cross-project sharing
`registries` in `components.json` maps `@team` namespaces to registry URLs; items install via `shadcn@latest add @team/<item>`. Build your own registry with `shadcn@latest build` from a `registry.json` (`name`, `homepage`, `items` with `registry:ui` types) or point `registries` at a GitHub repo — see `references/registry-format.md` and S5.

## Anti-patterns
- Hand-writing a primitive the registry has (S1) — `add` it instead.
- Hex color literals in variants (S4) — colors come from CSS variables (`bg-primary`, `text-destructive`).
- New looks via wrapper classes instead of a variant (S2) — add the variant, `cn()` merges the rest.
- Editing a generated file beyond a variant without a `shadcn modified:` registry note (S3).
