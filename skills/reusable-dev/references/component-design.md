# Component design rules

Principles → checkable rules → anti-patterns → example. Stack syntax lives in `stacks/<stack>.md`; ui-lib specifics in `ui-libs/<ui_lib>.md`.

## Layers

`primitives` (Button, Input) → `patterns` (FormField, DataTable) → `feature` (OrdersTable) → `page`.
A layer may import only from layers to its left. Shared code (`primitives`, `patterns`) never imports from `feature` or `page`.

## Rules

| ID | Rule | How to check |
|---|---|---|
| C1 | Shared components import nothing from feature/page folders. | grep imports in `shared_paths.components` for `features/` or `pages/`/`app/` |
| C2 | State and effects live in a hook/composable; the component renders. Shared UI does not fetch data. | no `fetch`/data-client calls in shared UI files |
| C3 | Visual alternatives are one `variant` (or `size`) enum prop, not booleans. | no props named `is<Adjective>` that change appearance |
| C4 | Content goes through children/slots, not config props (`title`, `footerText`, `icon`…) when it can be markup. | ≤ 2 string content props |
| C5 | Pass through remaining native props and ref to the root element. | rest spread on root element |
| C6 | Inputs support controlled (`value` + `onChange`) and uncontrolled (`defaultValue`) use. | both prop pairs present on form controls |
| C7 | No hardcoded user-facing text or colors in shared UI; use props/i18n and design tokens. | no hex/rgb literals; no literal sentences |
| C8 | Accessible baseline: semantic element, keyboard operable, labelled. | `button` not clickable `div`; inputs have label/aria-label |

## Warning signals (consider splitting or composing)

- More than 7 props.
- Two or more booleans that cannot be true together (`isPrimary` + `isDanger`).
- A copy of a component with a small change (`BlueCard` next to `Card`).
- A prop that is only passed through to one child (prop drilling across > 2 levels → context/provide).

## Extend without breaking

- New props are optional with a default equal to today's behavior.
- Never rename or remove a prop in the same change that adds one. Deprecate first: keep the old prop, map it to the new one, note `deprecated → <new>` in the registry.

## Example (framework-neutral pseudocode)

```
// ✗ Before: booleans + copied component
<Button isDanger />         <DangerButton />

// ✓ After: one variant enum on the existing primitive
<Button variant="destructive" />
```