<!-- researched 2026-09-14: nuxt@4.5.2, vue@3.5.42, vitest@5.0.0, @vue/test-utils@2.5.0, @nuxt/test-utils@4.3.2 (nuxt.com/docs, vuejs.org, vitest.dev) -->
# Stack: vue-nuxt

Nuxt 4 + Vue 3 `<script setup>`.

## Detection
`nuxt.config.*`, or `"nuxt"` / `"vue"` in package.json deps.

## Reuse units
- UI component: `app/components/BaseButton.vue` (auto-imported by Nuxt; `Base`/`App` prefix or `components/ui` subfolder for shared primitives).
- Stateful logic: composable `app/composables/useDebouncedValue.ts` (auto-imported; Nuxt scans top level of the dir only).
- Pure helpers: `app/utils/` (auto-imported) or `shared/` (Nuxt 4 shared dir for code usable by app + server).

## Paths
- Components: `app/components/` (nested dirs become name prefixes by default); composables: `app/composables/`; pure helpers: `app/utils/` or `shared/`.
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
- C5: undeclared attrs/listeners fall through automatically to the single root element (class/style merge; v-on listeners add). Multi-root components do NOT inherit attrs — set `inheritAttrs: false` and bind `$attrs` (or `useAttrs()`) explicitly. Ref exposure: `<script setup>` is closed by default — expose with `defineExpose({ focus })`, parent uses `useTemplateRef`/`ref` + `MyComp.value.exposed`.
- C6: `defineModel()` (Vue 3.4+) declares `modelValue` prop + `update:modelValue` event; supports `{ default }` for the uncontrolled pattern. Underlying spelling: prop `modelValue`, event `update:modelValue`.
- C4: named slots via `<slot name="footer" />` + `v-slot:footer`; type slots with `defineSlots`.
- If the component also must accept native input attrs, declare them as props or rely on fallthrough.

## Logic idioms
- F2: composables receive IO (api client, storage) as arguments; pure logic stays a plain function in `shared/` or `utils/`.
```ts
// F6 throw style (or return Result objects — follow error_style)
export class NotFoundError extends Error {
  constructor(id: string) { super(`resource ${id} not found`); }
}
```

## Testing
- Vitest + `@vue/test-utils` (`mount`), or `mountSuspended` from `@nuxt/test-utils` to mount within the real Nuxt environment (auto-imports, plugins). Install per Nuxt docs: `npm i -D @nuxt/test-utils vitest @vue/test-utils happy-dom`.
- One file: `npx vitest run path/to/file.test.ts` (substring filter also works; `vitest run` = no watch).

## Stack-specific anti-patterns
- Mixins and `this.$parent` — use composables and props/events.
- Global event bus — use composables or provide/inject scoped to a feature.
- Business logic inside `pages/` — pages compose; logic goes to composables and server code.
- Auto-import deep nesting — only top-level files of `composables/` and `utils/` are scanned; re-export from an `index.ts` or configure the scanner.
- Importing server code into app code — server lives in `server/`, shared types in `shared/types/`.
