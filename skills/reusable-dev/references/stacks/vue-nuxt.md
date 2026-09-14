<!-- researched 2026-09-14: nuxt@4.5.2, vue@3.5.42, vitest@5.0.0, @vue/test-utils@2.5.0, @nuxt/test-utils@4.3.2 (nuxt.com/docs, vuejs.org, vitest.dev) -->
# Stack: vue-nuxt

Nuxt 4 + Vue 3 `<script setup>`.

## Detection
`nuxt.config.*`, or `"nuxt"` / `"vue"` in package.json deps.

## Reuse units
- UI component: `app/components/BaseButton.vue` (auto-imported by Nuxt; `Base`/`App` prefix or `components/shared` subfolder for shared primitives). Never put your own primitives in `components/ui` — that dir belongs to the shadcn-vue ui_lib and config-format.md says to ignore it.
- Stateful logic: composable `app/composables/useDebouncedValue.ts` (auto-imported; Nuxt scans top level of the dir only).
- Pure helpers: `app/utils/` (auto-imported) or `shared/utils/` (Nuxt 4 shared dir, usable by app + server; only `shared/utils/` and `shared/types/` are auto-imported — files in the `shared/` root need explicit `#shared/...` imports) (nuxt.com/docs, directory-structure/shared).

## Paths
- Components: `app/components/` (nested dirs become name prefixes by default); composables: `app/composables/`; pure helpers: `app/utils/` or `shared/utils/` (only `shared/utils/` + `shared/types/` auto-imported).
- Server vs app: server code ONLY in `server/` (api, routes, utils — Nitro auto-imports `server/utils/`, `defineEventHandler` from h3). Never import server code into app code or vice versa; types shared by both live in `shared/types/` (Nuxt 4 docs, directory-structure/server).
- Cross-app sharing: Nuxt layers — a layer is a partial Nuxt app with its own `nuxt.config.ts`, consumed via `extends` or the `~~/layers` dir (nuxt.com/docs, Authoring Nuxt Layers).

## Component idioms
```vue
<script setup lang="ts">
// C3 variant enum + C6 controlled via defineModel
type Variant = 'default' | 'destructive';
const { variant = 'default', size = 'md' } =
  defineProps<{ variant?: Variant; size?: 'sm' | 'md' }>();
const model = defineModel<string>(); // C6: prop `modelValue` + event `update:modelValue`
</script>
<template>
  <!-- C4: content through the default slot; C5: fallthrough attrs land on root -->
  <button :data-variant="variant"><slot /></button>
</template>
```
- C5: undeclared attrs/listeners fall through automatically to the single root element (class/style merge; v-on listeners add). Multi-root components get NO automatic fallthrough — set `inheritAttrs: false` via `defineOptions` in `<script setup>` and bind `$attrs` (or `useAttrs()`) explicitly (vuejs.org guide, Fallthrough Attributes). Ref exposure: `<script setup>` is closed by default — expose with `defineExpose({ focus })`; the parent's template ref returns that exposed shape directly (refs unwrapped): `const compRef = useTemplateRef('comp')`, then `compRef.value.focus()` — no `.exposed` (vuejs.org/api/sfc-script-setup, defineExpose).
- C6: `defineModel()` (Vue 3.4+) declares `modelValue` prop + `update:modelValue` event; supports `{ default }` for the uncontrolled pattern. Underlying spelling: prop `modelValue`, event `update:modelValue`.
- C4: named slots via `<slot name="footer" />` + `v-slot:footer`; type slots with `defineSlots`.
- If the component also must accept native input attrs, declare them as props or rely on fallthrough.

## Logic idioms
- F2: composables receive IO (api client, storage) as arguments; pure logic stays a plain function in `shared/utils/` or `app/utils/`.
```ts
// F6 throw style
export class NotFoundError extends Error {
  constructor(id: string) { super(`resource ${id} not found`); }
}
```
- F6 result style (`error_style: result`): return `{ ok: true, value } | { ok: false, error }` — pick ONE per config error_style, never mix.

## Testing
- Plain unit tests: Vitest + `@vue/test-utils` (`mount`). `mountSuspended` from `@nuxt/test-utils` mounts within the real Nuxt environment (auto-imports, plugins) — it needs the `nuxt` Vitest environment (nuxt.com/docs/4.x/getting-started/testing): a `// @vitest-environment nuxt` comment in the file, or `environment: 'nuxt'` via `defineVitestConfig`/`defineVitestProject`, or tests under `test/nuxt/` / named `*.nuxt.spec.ts`. Install per Nuxt docs: `npm i -D @nuxt/test-utils vitest @vue/test-utils happy-dom`.
- One file (nuxt env): `npx vitest run test/nuxt/components.nuxt.spec.ts` (or `npx vitest run --project nuxt <file>` with the project setup). Plain unit test: `npx vitest run test/unit/money.test.ts` (substring filter also works; `vitest run` = no watch).

## Stack-specific anti-patterns
- Mixins and `this.$parent` — use composables and props/events.
- Global event bus — use composables or provide/inject scoped to a feature.
- Business logic inside `app/pages/` — pages compose; logic goes to composables and server code.
- Auto-import deep nesting — only top-level files of `composables/` and `utils/` are scanned; re-export from an `index.ts` or configure the scanner. Same for `shared/`: only `shared/utils/` and `shared/types/` are auto-imported.
- Importing server code into app code — server lives in `server/`, shared types in `shared/types/`.
