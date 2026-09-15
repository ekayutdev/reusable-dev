# reusable-dev Phase 2b — Laravel, Rust (axum), SwiftUI — Design Spec

- **วันที่:** 2026-09-15
- **สถานะ:** Implemented (phase 2b)
- **ต่อจาก:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2a-design.md` (implemented, merged)

## 1. เป้าหมาย

เพิ่ม stack `laravel`, `rust-axum`, `swiftui` ให้ plugin `reusable-dev` โดยใช้ workflow, กฎ C1–C8/F1–F8, report format, extension points และรูปแบบ eval ของ Phase 2a

### Non-goals
- ไม่มี Livewire, Inertia (Inertia ใช้ path map ไปยัง `react-next`/`vue-nuxt`), Vapor, Leptos/Dioxus
- ไม่แยก language core (`php.md`, `rust.md`, `swift.md`) — มี framework เดียวต่อภาษาในรอบนี้
- ไม่ติดตั้ง package (composer/cargo/SwiftPM dependencies) และ fixture ห้ามพึ่งเน็ต
- Phase 2c (`dotnet`) อยู่นอกขอบเขต

### Toolchain ในเครื่อง (ตรวจแล้ว 2026-09-15)
- PHP 8.3 + Composer ใช้ได้; ไม่มี phpunit/Pest
- Rust 1.98.1 (อัปเกรดผ่าน `rustup update stable` ด้วยความยินยอมของผู้ใช้ เพราะ 1.88 link กับ macOS 27 SDK ไม่ได้); `cargo test --offline` ผ่านกับ crate std-only; ไม่มี `axum` ใน cargo cache
- Swift 6.3; `swift test` + Swift Testing ผ่านกับ SwiftPM package macOS 14

## 2. ไฟล์ reference

```
skills/reusable-dev/references/stacks/
├── laravel.md
├── rust-axum.md
└── swiftui.md
```
ทุกไฟล์: section ตาม `stacks/_template.md`, ≤ 150 บรรทัด, ภาษาอังกฤษ, บรรทัดแรก `<!-- researched 2026-09-15: <lib>@<version>, … -->` จากเอกสารทางการ (laravel.com/docs, docs.rs/axum, developer.apple.com/documentation/swiftui, docs.swift.org), ห้ามมีชื่อไฟล์/ฟังก์ชันของ fixture

## 3. แก้ของเดิม

### 3.1 Detection ใน `references/config-format.md` (ใช้แถวแรกที่ตรง)

| # | Signal | Value |
|---|---|---|
| 1 | `next.config.*` or `"next"` in package.json deps | `react-next` |
| 2 | `nuxt.config.*` or `"nuxt"` in deps | `vue-nuxt` |
| 3 | `"@sveltejs/kit"` in deps | `sveltekit` |
| 4 | `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` | `django` |
| 5 | `fastapi` in `pyproject.toml` / `requirements*.txt` | `fastapi` |
| 6 | `artisan`, or `laravel/framework` in `composer.json` | `laravel` |
| 7 | `axum` in any `Cargo.toml` in the repo (root, member, or excluded crate) | `rust-axum` |
| 8 | `Package.swift` or `*.xcodeproj` present and `import SwiftUI` in a source file | `swiftui` |
| 9 | `"react"` without next → `react-next`; `"vue"` without nuxt → `vue-nuxt` | see signal |
| 10 | `"@nestjs/core"` in deps or `nest-cli.json` | `nestjs` |
| 11 | package.json with another server framework or no UI framework, and no Python/PHP/Rust/Swift manifest (`pyproject.toml`, `requirements*.txt`, `setup.py`, `composer.json`, `Cargo.toml`, `Package.swift`) at the same level | `node-ts` |
| 12 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `python` |

Rationale sentence (replaces the phase 2a one): `Backend and native frameworks (rows 4–8) come before bare UI-library deps (row 9) and generic package.json rows (10–11) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).`

ค่า `stack` ที่ถูกต้องเพิ่ม `laravel|rust-axum|swiftui`; ecosystem ที่ไม่มี reference เหลือ `go|php|rust|swift`

**`commands.test`:**
- Laravel: `vendor/bin/pest` exists → `vendor/bin/pest`; else `php artisan test`
- Rust: `cargo test`
- Swift: `Package.swift` → `swift test`; `*.xcodeproj` only → `xcodebuild test -scheme <scheme>` (scheme unknown → ask / leave `""`)

### 3.2 Source roots by language (เพิ่มแถว)

| Language | Roots | Skip |
|---|---|---|
| PHP | `app/`, `src/`, `resources/views/components/`, `packages/*` | `vendor/`, `storage/`, `bootstrap/cache/`, `node_modules` |
| Rust | `src/`, `crates/*` | `target/` |
| Swift | `Sources/*`, `Packages/*`, the app target folder | `.build/`, `DerivedData/` |

Shared paths (first that exists):
- Laravel: functions `app/Support`, `app/Actions`; components `resources/views/components`
- Rust: functions `crates/shared/src`, `src/shared`; components `""`
- SwiftUI: functions `Sources/Shared`, `Packages/Shared/Sources`; components `Sources/DesignSystem`, `Packages/DesignSystem/Sources`

### 3.3 README
บรรทัด Stacks เพิ่ม `Laravel · Rust (axum) · SwiftUI`

## 4. เนื้อหา references

### `laravel.md`
- Detection: row 6
- Reuse units: Action/Service classes resolved by the Service Container; Eloquent local scopes; Form Requests; Blade anonymous and class components
- Paths: `app/Actions`, `app/Services`, `app/Support` (pure helpers); `resources/views/components` (+ `app/View/Components` for class components)
- Component idioms: C3 `variant` prop via `@props([...])` + `$attributes->merge(['class' => …])`; C4 default slot + named `<x-slot:name>`; C5 `$attributes` forwarded to the root element; C6 controlled value via `value`/`old('field', $default)` + `name`, uncontrolled via default attribute only
- Logic idioms: F2 constructor injection (container), bind interfaces in a service provider; F6 domain exceptions rendered/reported in the exception handler (`bootstrap/app.php` `withExceptions`)
- Testing: Pest or PHPUnit; single file `php artisan test tests/Feature/XTest.php` / `vendor/bin/pest tests/Unit/XTest.php`
- Anti-patterns: fat controllers; logic in Blade; facades inside domain services (hard to test); copy-and-tweak components instead of `$attributes`

### `rust-axum.md`
- Detection: row 7
- Reuse units: workspace crates (`crates/<domain>`), modules by domain, traits for collaborators, `IntoResponse` error types, extractors
- Paths: `crates/api` (axum router/handlers) → `crates/<domain>` (pure logic) ; shared helpers `crates/shared`
- Component idioms: `Not applicable — no UI`
- Logic idioms: F2 handlers receive `State<AppState>` holding `Arc<dyn Trait>` or generic services; domain functions pure; F6 domain `enum` errors (`thiserror`) converted to responses with `impl IntoResponse`
- Testing: `cargo test -p <crate>`; single test `cargo test <name>`; handler tests with `tower::ServiceExt::oneshot`
- Anti-patterns: business logic in handlers; `unwrap()` in request paths; global `static mut`/lazy singletons for services; one giant `utils.rs`

### `swiftui.md`
- Detection: row 8
- Reuse units: small `View` structs, `ViewModifier` + `View` extension, `ButtonStyle`/`LabelStyle`, `@Observable` models, Swift Package targets (`DesignSystem`, `Shared`)
- Paths: `Sources/DesignSystem` (views/styles), `Sources/Shared` (pure functions), feature targets per domain
- Component idioms: C3 variants as an `enum` passed to a style (`.buttonStyle(.brand(.destructive))`); C4 content via `@ViewBuilder` closures; C5 accept modifiers from the caller (no refs; focus via `@FocusState` binding); C6 controlled = `Binding<Value>` parameter, uncontrolled = internal `@State` with an initial value
- Logic idioms: F2 inject dependencies via initializer or `@Environment` values; F6 `throws` with typed domain errors, views map errors to UI state
- Testing: Swift Testing (`@Test`, `#expect`); `swift test --filter <Suite>`; view logic tested through models/pure functions
- Anti-patterns: logic in `body`; copy-pasted modifier chains instead of `ViewModifier`; `@ObservedObject` models created inside views; massive views

## 5. Fixtures (`evals/fixtures/`)

ทุกตัว: `.claude/reusable-dev.md` ครบทุก key พร้อม `commands.test` ที่รันได้; `docs/reuse-registry.md`; helper จัดรูปเงินซ้ำใน 2 feature; feature ที่ 3 (customers) ยังไม่ใช้; test เดิม 2 ตัว

| Fixture | Signals | Duplicate helper | `commands.test` |
|---|---|---|---|
| `laravel` | `composer.json` (`laravel/framework`), `artisan`, `package.json` (vite, tooling only); plain-PHP service classes (no Illuminate imports) | private `formatMoney` in `app/Services/OrderService.php` and `app/Services/InvoiceService.php` | `php tests/run.php` (assert-based runner, prints `OK <n> tests`) |
| `rust-axum` | root `Cargo.toml` workspace `members = ["crates/billing"]`, `exclude = ["crates/api"]`; `crates/api/Cargo.toml` depends on `axum` | `format_money` in `crates/billing/src/orders.rs` and `crates/billing/src/invoices.rs` | `cargo test --offline` |
| `swiftui` | `Package.swift` (macOS 14) with targets `Orders`, `Invoices`, `Customers`; a SwiftUI view file per target | `formatMoney` in `Sources/Orders/OrderLabel.swift` and `Sources/Invoices/InvoiceLabel.swift` | `swift test` |

## 6. Evals

### 6.1 `14-rule-of-three-{laravel,rust-axum,swiftui}`
- Prompt: unhinted; names the target file and the expected text `Balance: $12.50`, with a test in a named file
- Graders: shared file created (`files` regex: laravel `app/(Support|Actions)/`; rust `crates/shared/src/…\.rs` or `crates/billing/src/(money|shared)…\.rs` (a module shared by all three domain modules in the same crate counts); swift `Sources/Shared/`); both originals no longer define the helper (`not_contains`); customers file references the shared helper (file-targeted regex); tests green counting ≥ 3 tests (laravel `OK (?:[3-9]|\d{2,}) tests`; rust `test result: ok\. (?:[3-9]|\d{2,}) passed`; swift `with (?:[3-9]|\d{2,}) tests? .* passed`); original test assertions kept; `Reuse decision:\s*Create`; `skill-fired` display only

### 6.2 `15-setup-detects-{laravel,rust-axum,swiftui}`
Pattern of phase 2a case 15: Write attempted to `reusable-dev.md`; Write input has `stack:\s*<stack>` and the expected `commands.test`; `no-bash-config-workaround` (min 0, max 0). Laravel fixture includes a tooling package.json to prove row 6 wins over row 11.

### 6.3 Regression
Cases `01`, `02`, `04`, `10`, `11`, `15-setup-detects-django` — 1 run each, with-plugin 1.00.

### 6.4 Sandbox toolchain probe (first plan task)
Verify inside `claude plugin eval` that `cargo` and `swift` run (the sandbox hid `~/.local/bin` in phase 1). If a toolchain is unavailable in the sandbox: that fixture's `commands.test` becomes `""`, its tests-green graders are replaced by `Verified:[^\n]*T2 skipped`, and the decision is recorded.

**Probe result (2026-09-15, `evals/00b-harness-toolchains`):** cargo `cargo test --offline` ✗: `error: rustup could not choose a version of cargo to run, because one wasn't specified explicitly, and no default is configured.`; swift ✗: `swift: error: couldn't create cache file '/var/folders/hb/s6_sbf857qg2bxfvv0fdq_g00000gn/T/xcrun_db-KnW1OzqO' (errno=Operation not permitted)`; php ✓.

## 7. Error handling
- `composer.json` without Laravel → ecosystem `php` (general rules + Notes)
- `Cargo.toml` without axum → ecosystem `rust`
- Swift without SwiftUI imports → ecosystem `swift`
- `*.xcodeproj` without a known scheme → `commands.test: ""` → `T2 skipped (no command)`

## 8. Acceptance
- `claude plugin validate . --strict`; references ≤ 150 lines; SKILL.md unchanged
- 6 new cases with-plugin 1.00 (1 run each, one at a time); regression cases 1.00
- Always-on token cost unchanged (~761); leak grep for fixture names empty
