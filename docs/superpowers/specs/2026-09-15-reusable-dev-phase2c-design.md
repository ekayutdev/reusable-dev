# reusable-dev Phase 2c — .NET (ASP.NET Core API + Blazor) — Design Spec

- **วันที่:** 2026-09-15
- **สถานะ:** Approved design, รอรีวิว spec
- **ต่อจาก:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md` (implemented, merged)

## 1. เป้าหมาย

เพิ่ม stack `dotnet` (ASP.NET Core API + Blazor ในไฟล์ reference เดียว) ให้ plugin `reusable-dev` โดยใช้ workflow, กฎ C1–C8/F1–F8, report format, extension points และรูปแบบ eval เดิม (1 เคส Rule of Three + 1 เคส `/reuse-setup` detect)

### Non-goals
- ไม่มี F#, MAUI, WPF/WinForms, Razor Pages/MVC views แยก (ใช้ general rules ของ `dotnet.md`)
- ไม่ติดตั้ง package ใหม่ (รวม bUnit) และ fixture ห้ามพึ่งเน็ต — ใช้เฉพาะ NuGet cache ที่มี (xunit 2.4.2, xunit.runner.visualstudio 2.4.5, Microsoft.NET.Test.Sdk 17.6.0)
- ไม่ทำ Blazor render test ใน eval (bUnit ไม่อยู่ใน cache)

### Toolchain ในเครื่อง (ตรวจแล้ว 2026-09-15)
- .NET SDK 8.0.203 (มี 6.x/7.x ด้วย), ASP.NET Core runtime 8.0.3
- classlib + xunit test project: `dotnet test` restore จาก cache ได้แบบ offline, ผลลัพธ์ `Passed!  - Failed:     0, Passed:     1, ...`
- `Microsoft.NET.Sdk.Web` project ที่มี `.razor` component build ได้ offline (shared framework)

## 2. ไฟล์ reference

```
skills/reusable-dev/references/stacks/dotnet.md
```
section ตาม `stacks/_template.md`, ≤ 150 บรรทัด, ภาษาอังกฤษ, บรรทัดแรก `<!-- researched 2026-09-15: <lib>@<version>, … -->` จาก learn.microsoft.com (aspnet/core fundamentals DI/options/minimal APIs/error handling, blazor components/parameters/templated components/splat attributes/data binding/RCL, dotnet core testing), ไม่มีบรรทัด `Read <core>.md first.`, ห้ามมีชื่อไฟล์/ฟังก์ชัน/คลาสของ fixture

## 3. แก้ของเดิม

### 3.1 Detection ใน `references/config-format.md`

แทรกแถวใหม่หลัง swiftui และเลื่อนแถวเดิม 9–12 เป็น 10–13:

| # | Signal | Value |
|---|---|---|
| 9 | `*.sln` at the root, or `*.csproj` at the root or in `src/*/` | `stack: dotnet` |
| 10 | `"react"` without next → `react-next`; `"vue"` without nuxt → `vue-nuxt` | see signal |
| 11 | `"@nestjs/core"` in deps or `nest-cli.json` | `stack: nestjs` |
| 12 | package.json with another server framework or no UI framework, and no `pyproject.toml` / `requirements*.txt` / `setup.py` / `composer.json` / `Cargo.toml` / `Package.swift` / `*.sln` / `*.csproj` at the same level | `stack: node-ts` |
| 13 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `stack: python` |

Rationale sentence: `Backend and native frameworks (rows 4–9) come before bare UI-library deps (row 10) and generic package.json rows (11–12) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).`

- ค่า `stack` ที่ถูกต้องเพิ่ม `dotnet`
- `commands` row ใหม่: `.NET: \`commands.test: dotnet test\`; \`commands.build: dotnet build\``
- `stacks/nestjs.md` อ้าง `detection row 10` → `detection row 11`

### 3.2 Source roots และ shared paths
| Language | Roots | Skip |
|---|---|---|
| C# | `src/*`, `tests/*`, project folders next to the `*.sln` | `bin/`, `obj/`, `node_modules` |

`.NET shared paths (first that exists): functions \`src/Shared\`, \`src/*.Shared\`; components \`src/*/Components/Shared\`, \`src/*.Components\`.`

### 3.3 Cross-cutting lists
- `agents/duplicate-finder.md` step 2 declaration grep: เพิ่ม C# method form `(public|private|protected|internal)[\w<>\[\], ]*\s\w+\(`; step 4 test locations: เพิ่ม `tests/*.Tests/`
- `references/verification.md` T3 step 2: เพิ่ม C# `using <Namespace>`; step 3: เพิ่ม `tests/*.Tests/`
- `commands/reuse-setup.md` step 2: เพิ่ม `*.sln`/`*.csproj` ในรายการไฟล์ที่อ่าน

### 3.4 README
บรรทัด Stacks เพิ่ม `.NET (ASP.NET Core · Blazor)`

## 4. เนื้อหา `dotnet.md`
- Detection: row 9
- Reuse units: class library per domain (`src/<Domain>`); services registered in DI; extension methods; minimal API endpoint groups (`MapGroup`) or controllers; Razor components with parameters; Razor class libraries (RCL) for shared UI
- Paths: `src/<App>.Api` or `src/Web` (endpoints, components) → `src/<Domain>` (pure logic, no ASP.NET references) → `src/Shared`; shared components in `Components/Shared` or an RCL
- Component idioms: C3 `[Parameter] public ButtonVariant Variant` enum mapped to CSS classes; C4 `ChildContent` `RenderFragment` + named `RenderFragment` parameters; C5 `[Parameter(CaptureUnmatchedValues = true)] Dictionary<string, object>` + `@attributes`, refs via `@ref` / `ElementReference`; C6 controlled `Value` + `ValueChanged` `EventCallback<T>` (`@bind-Value`), uncontrolled = internal field with an initial value
- Logic idioms: F2 constructor injection, interfaces registered in `Program.cs` (`AddScoped<IX, X>()`), `IOptions<T>` for settings; F6 domain exceptions mapped once by `IExceptionHandler` / `TypedResults.Problem`, or a `Result<T>` type when `error_style: result`
- Testing: xUnit / NUnit / MSTest; `dotnet test --filter FullyQualifiedName~<Name>`; API tests with `WebApplicationFactory<Program>`; component tests with bUnit when installed; use exactly config `commands.test` and run nothing when it is empty
- Anti-patterns: business logic in endpoints/controllers or `@code` blocks; injecting `IServiceProvider` (service locator); `.Result` / `.Wait()` and `async void`; copy-pasted components instead of parameters / `RenderFragment`

## 5. Fixture `evals/fixtures/dotnet`

| Part | Content |
|---|---|
| Solution | `Billing.sln` (generated by `dotnet new sln` + `dotnet sln add`, committed verbatim) with the three projects below |
| `src/Billing` | classlib net8.0: `OrderService` and `InvoiceService` each with a private static `FormatMoney(long cents)`; `Customer` record (`Id`, `Name`, `BalanceCents`) |
| `src/Web` | `Microsoft.NET.Sdk.Web`: minimal API `Program.cs` using `OrderService`; `Components/OrderSummary.razor` (context only) |
| `tests/Billing.Tests` | xunit 2.4.2 + runner 2.4.5 + Test SDK 17.6.0; `OrderServiceTests` (`Order total: $25.00`) and `InvoiceServiceTests` (`Amount due: $3.50`) |
| Tooling | root `package.json` (tailwindcss, tooling only) — proves row 9 wins over rows 10–12 |
| Config | `.claude/reusable-dev.md`: `stack: dotnet`, `shared_paths.functions: src/Shared`, `components: src/Web/Components/Shared`, `commands.test: dotnet test`, `commands.build: ""` ; `docs/reuse-registry.md` |

`.gitignore` เพิ่ม `evals/fixtures/**/bin/` และ `evals/fixtures/**/obj/`; รัน fixture test เฉพาะใน temp copy

## 6. Evals

### 6.1 `14-rule-of-three-dotnet`
- Prompt: `Add a BalanceLabel(Customer customer) method to a new CustomerService class in src/Billing/CustomerService.cs that returns text like "Balance: $12.50" from customer.BalanceCents, with an xunit test in tests/Billing.Tests/CustomerServiceTests.cs.`
- Graders:
  - `shared-module-created` (files): `(^|\n)src/(Shared|Billing\.Shared|Billing/Shared|Billing/Common)/[^\n]*\.cs`
  - `orders-no-local-copy`, `invoices-no-local-copy`, `customers-no-local-copy` (file, `not_contains`): `string FormatMoney\(`
  - `customers-uses-shared` (file `src/Billing/CustomerService.cs`): `\w+\.(Format|ToMoney)\w*\(|using Billing\.(Shared|Common)\b`
  - `tests-green` (trace): `Passed!\s+-\s+Failed:\s+0,\s+Passed:\s+(?:[3-9]|\d{2,})`
  - `orders-assertion-kept` / `invoices-assertion-kept`
  - `reports-create`: `Reuse decision:\s*Create`
  - `skill-fired` (display only)

### 6.2 `15-setup-detects-dotnet`
Pattern ของเคส 15 เดิม: Write attempted ไป `reusable-dev.md`; Write input มี `stack:\s*dotnet` และ `test:\s*\\?"?dotnet test`; `no-bash-config-workaround` (min 0, max 0)

### 6.3 Regression
`01`, `02`, `04`, `10`, `11`, `15-setup-detects-django`, `15-setup-detects-laravel` — 1 run each, with-plugin 1.00

### 6.4 Sandbox toolchain probe (first plan task)
Throwaway case (not committed after recording) runs `dotnet test` on a minimal classlib + xunit project inside `claude plugin eval`, in two variants: plain, and with `DOTNET_CLI_HOME="$PWD/.dotnet-home" DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1`. Result recorded in this section.
- Plain ✓ → `commands.test: dotnet test`
- Only the env variant ✓ → fixture `commands.test` uses that variant; case 15 still expects `dotnet test`
- Both ✗ → fixture `commands.test: ""`; `tests-green` replaced by `reports-t2-skipped` (`Verified:[^\n]*T2 skipped`); plus a static wiring grader: a new project must appear in `tests/Billing.Tests/Billing.Tests.csproj` or `src/Billing/Billing.csproj` as a `ProjectReference` — `shared-wired` (trace): `ProjectReference Include="[^"]*Shared[^"]*\.csproj"|src/Billing/(Shared|Common)/` (a folder inside `src/Billing` needs no wiring, SDK-style projects include every `.cs` file)

No `llm` grader checks file state (phase 2b lesson: without `focus` it only sees the final message).

## 7. Error handling
- `*.fsproj` only → ecosystem `fsharp` (general rules + Notes)
- `*.sln` in a subfolder only → no row 9 match at root; monorepo path map row applies
- `dotnet` missing or `commands.test` fails to start → `T2 could not run (<error>)` per verification.md

## 8. Acceptance
- `claude plugin validate . --strict`; `dotnet.md` ≤ 150 lines; SKILL.md unchanged
- 2 new cases with-plugin 1.00 (1 run each); regression cases 1.00
- Leak grep empty for `FormatMoney`, `OrderService`, `InvoiceService`, `CustomerService`, `BalanceLabel`, `OrderSummary` in `skills/`, `commands/`, `agents/`
- Probe case removed after its result is recorded (no always-failing case in `evals/`)
