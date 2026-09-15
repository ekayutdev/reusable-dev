# reusable-dev Phase 2c (.NET: ASP.NET Core API + Blazor) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `dotnet` stack (ASP.NET Core API + Blazor in one reference) to the reusable-dev plugin: detection row 9, C# source roots and cross-cutting patterns, `stacks/dotnet.md`, an offline fixture and two eval cases.

**Architecture:** A throwaway probe first decides whether `dotnet test` can run inside the eval sandbox. Detection inserts row 9 before the bare UI-library and generic package.json rows (renumbering 9–12 to 10–13). The fixture is a three-project solution (classlib with the duplicated helper, a Web project with Blazor components for context, an xunit project using only packages already in the NuGet cache).

**Tech Stack:** Claude Code plugin (Markdown), `claude plugin eval` via `evals/lib/run-eval.sh`, .NET SDK 8.0.203, xunit 2.4.2 / xunit.runner.visualstudio 2.4.5 / Microsoft.NET.Test.Sdk 17.6.0 (from `~/.nuget/packages`).

**Spec:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2c-design.md`

## Global Constraints

- Do not install, uninstall or upgrade software or NuGet packages (no brew, dotnet workload/tool install, `dotnet add package`, new package versions). Only the cached versions xunit 2.4.2, xunit.runner.visualstudio 2.4.5, Microsoft.NET.Test.Sdk 17.6.0. No bUnit.
- Run fixture builds/tests only in a temporary copy, never inside `evals/fixtures/`: `tmp=$(mktemp -d) && cp -R evals/fixtures/<name>/. "$tmp" && (cd "$tmp" && <command>)`. `git status --porcelain evals/fixtures` must never list `bin/` or `obj/`.
- Run evals only via `evals/lib/run-eval.sh --runs 1 --case <name>`, one case per command, sequentially. After each run: `ls -d ~/.docker` exists and `~/.docker.eval-stash` does not; otherwise run `evals/lib/run-eval.sh --restore` and stop. Never restart a stopped eval on your own. At most 2 eval runs per implementer dispatch (the host kills long dispatches when memory is low); the controller runs any further evals.
- `dotnet.md`: ≤ 150 lines, English, section order of `stacks/_template.md`, first line `<!-- researched 2026-09-15: <lib>@<version>, … -->` from learn.microsoft.com, no `Read <core>.md first.` line, code examples from unrelated domains (shipments, reports, dates), never money/orders/invoices/customers.
- SKILL.md unchanged. Report prefixes, ladder, tiers, extension points unchanged.
- New `stack` value exactly `dotnet`.
- Never put these names in `skills/`, `commands/`, `agents/`: `FormatMoney`, `format_money`, `formatMoney`, `OrderService`, `InvoiceService`, `CustomerService`, `BalanceLabel`, `balanceLabel`, `OrderSummary`, `OrderTotalLabel`, `AmountDueLabel`.
- Graders: `tool_used` with `max: 0` also needs `min: 0`; trace output is JSON-escaped; no `llm` grader for file state (without `focus` it sees only the final message); YAML prompts/patterns with backslashes are single-quoted scalars.
- Every setup.sh: `#!/bin/bash`, `set -euo pipefail`, executable, calls `"$(dirname "$0")/../lib/use-fixture.sh" <fixture> [--no-config]`.
- Fixture config bodies never mention evals, sandboxes, or how tests are graded.
- Commit after every task. Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
  ```

---

## File Structure

```
.gitignore                                                        Task 1 (bin/, obj/ under fixtures)
docs/superpowers/specs/2026-09-15-reusable-dev-phase2c-design.md  Task 1 (probe result), Task 4 (status)
skills/reusable-dev/references/config-format.md                   Task 2
skills/reusable-dev/references/verification.md                    Task 2
skills/reusable-dev/references/stacks/nestjs.md                   Task 2 (row 10 → 11)
agents/duplicate-finder.md                                        Task 2
commands/reuse-setup.md                                           Task 2
README.md                                                         Task 2
skills/reusable-dev/references/stacks/dotnet.md                   Task 3
evals/fixtures/dotnet/**                                          Task 3
evals/14-rule-of-three-dotnet/, evals/15-setup-detects-dotnet/    Task 3
```

---

### Task 1: Sandbox probe for `dotnet test` (throwaway)

**Files:**
- Modify: `.gitignore`
- Modify: spec §6.4 (append the probe result)
- Temporary (deleted before commit): `evals/fixtures/dotnet-probe/**`, `evals/00c-probe-dotnet/{case.yaml,setup.sh}`

**Interfaces:**
- Produces: a `Probe result` line in spec §6.4: plain `dotnet test` ✓/✗; env variant ✓/✗. Task 3 reads it.

- [ ] **Step 1: Ignore fixture build output**

Append to `.gitignore`:
```
evals/fixtures/**/bin/
evals/fixtures/**/obj/
```

- [ ] **Step 2: Create the temporary probe fixture**

`evals/fixtures/dotnet-probe/probe-dotnet/Probe/Probe.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

`evals/fixtures/dotnet-probe/probe-dotnet/Probe/ProbeValue.cs`
```csharp
namespace Probe;

public static class ProbeValue
{
    public static string Get() => "ok";
}
```

`evals/fixtures/dotnet-probe/probe-dotnet/Probe.Tests/Probe.Tests.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.6.0" />
    <PackageReference Include="xunit" Version="2.4.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.4.5" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../Probe/Probe.csproj" />
  </ItemGroup>

</Project>
```

`evals/fixtures/dotnet-probe/probe-dotnet/Probe.Tests/ProbeTests.cs`
```csharp
namespace Probe.Tests;

public class ProbeTests
{
    [Fact]
    public void ProbeRuns() => Assert.Equal("ok", ProbeValue.Get());
}
```

- [ ] **Step 3: Verify the probe fixture on the host**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/dotnet-probe/. "$tmp" && (cd "$tmp/probe-dotnet/Probe.Tests" && dotnet test 2>&1 | grep -E "Passed!|Failed!|error")
```
Expected: `Passed!  - Failed:     0, Passed:     1`.

- [ ] **Step 4: Create the temporary probe case**

`evals/00c-probe-dotnet/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" dotnet-probe
```

`evals/00c-probe-dotnet/case.yaml`
```yaml
schema_version: "1.0"
name: 00c-probe-dotnet
description: Temporary probe — can the eval sandbox run dotnet test.
tags: [harness]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Run these two commands with the Bash tool, one Bash call each, exactly as written, and report the exit code of each: `(cd probe-dotnet/Probe.Tests && dotnet test)`, `(cd probe-dotnet/Probe.Tests && DOTNET_CLI_HOME="$PWD/.dotnet-home" DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 dotnet test)`. Do not edit any file.'
  max_turns: 8
  allowed_tools: [Bash, Read]
runs: 1
graders:
  - type: regex
    name: dotnet-tests
    target: trace
    pattern: 'Passed!\s+-\s+Failed:\s+0,\s+Passed:\s+1'
```

`chmod +x evals/00c-probe-dotnet/setup.sh`

- [ ] **Step 5: Run the probe and read the trace**

Run: `evals/lib/run-eval.sh --runs 1 --case 00c-probe-dotnet --keep-temp`
Read `<kept>/out/trace.jsonl` read-only. For each of the two commands note the exit code and the first error line (e.g. permission denied under `~/.dotnet`, `~/.nuget`, or the temp dir). A ✗ is a valid result; do not change sandbox settings, PATH, or run-eval.sh.

- [ ] **Step 6: Record the result and delete the probe**

Append to the end of spec §6.4:
```markdown

**Probe result (2026-09-15, temporary case `00c-probe-dotnet`, removed):** plain `dotnet test` <✓|✗: first error line>; env variant <✓|✗: first error line>.
```
Then: `rm -rf evals/00c-probe-dotnet evals/fixtures/dotnet-probe` and confirm `git status --porcelain evals` prints nothing.

- [ ] **Step 7: Commit**

```bash
git add .gitignore docs/superpowers/specs/2026-09-15-reusable-dev-phase2c-design.md
git commit -m "test: record eval-sandbox probe result for dotnet test"
```

---

### Task 2: Detection row 9, C# roots, cross-cutting patterns

**Files:**
- Modify: `skills/reusable-dev/references/config-format.md`, `skills/reusable-dev/references/verification.md`, `skills/reusable-dev/references/stacks/nestjs.md`, `agents/duplicate-finder.md`, `commands/reuse-setup.md`, `README.md`

**Interfaces:**
- Produces: detection row 9 `dotnet`; `.NET` commands row; C# roots and .NET shared paths. Used by Task 3.

- [ ] **Step 1: Detection rationale and rows in `config-format.md`**

Replace the line
```
Backend and native frameworks (rows 4–8) come before bare UI-library deps (row 9) and generic package.json rows (10–11) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).
```
with
```
Backend and native frameworks (rows 4–9) come before bare UI-library deps (row 10) and generic package.json rows (11–12) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).
```

Replace the four table rows starting `| 9 |`, `| 10 |`, `| 11 |`, `| 12 |` with:
```markdown
| 9 | `*.sln` at the root, or `*.csproj` at the root or in `src/*/` | `stack: dotnet` |
| 10 | `"react"` in deps without next → `stack: react-next`; `"vue"` in deps without nuxt → `stack: vue-nuxt` | see signal |
| 11 | `"@nestjs/core"` in deps or `nest-cli.json` | `stack: nestjs` |
| 12 | package.json with another server framework (`express`, `fastify`, `hono`) or no UI framework, and no `pyproject.toml` / `requirements*.txt` / `setup.py` / `composer.json` / `Cargo.toml` / `Package.swift` / `*.sln` / `*.csproj` at the same level (tsconfig.json optional) | `stack: node-ts` |
| 13 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `stack: python` |
```

After the table row starting `| – | Swift:` add:
```markdown
| – | .NET: `commands.test: dotnet test`; `commands.build: dotnet build` | `commands.test`, `commands.build` |
```

- [ ] **Step 2: Allowed `stack` values**

In the schema comment replace `| laravel | rust-axum | swiftui, or an ecosystem name (go | php | rust | swift, no reference file)` with `| laravel | rust-axum | swiftui | dotnet, or an ecosystem name (go | php | rust | swift | fsharp, no reference file)`.

- [ ] **Step 3: Source roots and shared paths**

After the table row starting `| Swift |` in `## Source roots by language` add:
```markdown
| C# | `src/*`, `tests/*`, project folders next to the `*.sln` | `bin/`, `obj/`, `node_modules` |
```
At the end of the paragraph starting `Laravel shared paths (first that exists)` append:
```
 .NET: functions `src/Shared`, `src/*.Shared`; components `src/*/Components/Shared`, `src/*.Components`.
```

- [ ] **Step 4: `stacks/nestjs.md`**

Replace `(detection row 10)` with `(detection row 11)`.

- [ ] **Step 5: `agents/duplicate-finder.md`**

In Procedure step 2 replace `` `fn \w+`, `func \w+`) `` with `` `fn \w+`, `func \w+`, C# `(public|private|protected|internal)[\w<>\[\],? ]*\s\w+\(`) ``.
In step 4 replace `` PHP `tests/**/*Test.php` — `` with `` PHP `tests/**/*Test.php`, C# `tests/*.Tests/` — ``.

- [ ] **Step 6: `references/verification.md`**

In "Finding call sites (T3)" step 2 replace `` Swift `import <Module>`, `` with `` Swift `import <Module>`, C# `using <Namespace>`, ``.
In step 3 replace `` PHP `tests/**/*Test.php`. `` with `` PHP `tests/**/*Test.php`, C# `tests/*.Tests/`. ``.

- [ ] **Step 7: `commands/reuse-setup.md` step 2**

Replace `go.mod/pyproject.toml/composer.json/Cargo.toml/Package.swift)` with `go.mod/pyproject.toml/composer.json/Cargo.toml/Package.swift/*.sln/*.csproj)`, and after `` `swift` for Package.swift or `*.xcodeproj` without SwiftUI`` insert `` , `fsharp` for `*.fsproj` without `*.csproj` ``.

- [ ] **Step 8: README**

Replace `· Laravel · Rust (axum) · SwiftUI` with `· Laravel · Rust (axum) · SwiftUI · .NET (ASP.NET Core · Blazor)`.

- [ ] **Step 9: Validate and check references**

Run:
```bash
claude plugin validate . --strict
wc -l skills/reusable-dev/references/config-format.md
grep -rn "rows\? [0-9]" skills commands agents README.md
git diff --stat
```
Expected: validation passed; config-format.md ≤ 150; row references: django 4, fastapi 5, laravel 6, rust-axum 7, swiftui 8, nestjs 11, rationale 4–9/10/11–12; diff touches only the six files.

- [ ] **Step 10: Commit**

```bash
git add skills/reusable-dev/references/config-format.md skills/reusable-dev/references/verification.md skills/reusable-dev/references/stacks/nestjs.md agents/duplicate-finder.md commands/reuse-setup.md README.md
git commit -m "feat: detect dotnet stack and add C# discover patterns"
```

- [ ] **Step 11: Regression evals (controller runs these, one per command)**

```bash
evals/lib/run-eval.sh --runs 1 --case 01-extend-button-react
evals/lib/run-eval.sh --runs 1 --case 02-reuse-existing-function
evals/lib/run-eval.sh --runs 1 --case 04-rule-of-three
evals/lib/run-eval.sh --runs 1 --case 10-audit-reports-without-editing
evals/lib/run-eval.sh --runs 1 --case 11-setup-writes-config
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-django
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-laravel
```
Expected: with-plugin 1.00 for each.

---

### Task 3: .NET reference, fixture, evals

**Files:**
- Create: `skills/reusable-dev/references/stacks/dotnet.md`
- Create: `evals/fixtures/dotnet/**` (Step 1)
- Create: `evals/14-rule-of-three-dotnet/{case.yaml,setup.sh}`, `evals/15-setup-detects-dotnet/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: detection row 9, `.NET` commands row, C# roots and .NET shared paths (Task 2); spec §6.4 probe result (Task 1).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/dotnet/package.json`
```json
{
  "private": true,
  "devDependencies": { "tailwindcss": "^4.0.0" }
}
```

`evals/fixtures/dotnet/src/Billing/Billing.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

`evals/fixtures/dotnet/src/Billing/Customer.cs`
```csharp
namespace Billing;

public sealed record Customer(string Id, string Name, long BalanceCents);
```

`evals/fixtures/dotnet/src/Billing/OrderService.cs`
```csharp
namespace Billing;

public sealed class OrderService
{
    public string OrderTotalLabel(IEnumerable<(long Cents, int Quantity)> lines)
    {
        var total = lines.Sum(line => line.Cents * line.Quantity);
        return $"Order total: {FormatMoney(total)}";
    }

    private static string FormatMoney(long cents) => $"${cents / 100}.{cents % 100:00}";
}
```

`evals/fixtures/dotnet/src/Billing/InvoiceService.cs`
```csharp
namespace Billing;

public sealed class InvoiceService
{
    public string AmountDueLabel(IEnumerable<long> amounts) => $"Amount due: {FormatMoney(amounts.Sum())}";

    private static string FormatMoney(long cents) => $"${cents / 100}.{cents % 100:00}";
}
```

`evals/fixtures/dotnet/src/Web/Web.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="../Billing/Billing.csproj" />
  </ItemGroup>

</Project>
```

`evals/fixtures/dotnet/src/Web/Program.cs`
```csharp
using Billing;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<OrderService>();
builder.Services.AddRazorComponents();

var app = builder.Build();
app.MapGet("/orders/total", (OrderService orders) => orders.OrderTotalLabel([(1000, 2), (500, 1)]));
app.Run();
```

`evals/fixtures/dotnet/src/Web/Components/_Imports.razor`
```razor
@using Microsoft.AspNetCore.Components
@using Microsoft.AspNetCore.Components.Web
@using Billing
```

`evals/fixtures/dotnet/src/Web/Components/OrderSummary.razor`
```razor
@inject OrderService Orders

<p class="order-summary">@Orders.OrderTotalLabel(Lines)</p>

@code {
    [Parameter, EditorRequired] public IReadOnlyList<(long Cents, int Quantity)> Lines { get; set; } = [];
}
```

`evals/fixtures/dotnet/tests/Billing.Tests/Billing.Tests.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.6.0" />
    <PackageReference Include="xunit" Version="2.4.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.4.5" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../src/Billing/Billing.csproj" />
  </ItemGroup>

</Project>
```

`evals/fixtures/dotnet/tests/Billing.Tests/OrderServiceTests.cs`
```csharp
namespace Billing.Tests;

public class OrderServiceTests
{
    [Fact]
    public void SumsLines() =>
        Assert.Equal("Order total: $25.00", new OrderService().OrderTotalLabel([(1000, 2), (500, 1)]));
}
```

`evals/fixtures/dotnet/tests/Billing.Tests/InvoiceServiceTests.cs`
```csharp
namespace Billing.Tests;

public class InvoiceServiceTests
{
    [Fact]
    public void SumsAmounts() =>
        Assert.Equal("Amount due: $3.50", new InvoiceService().AmountDueLabel([100, 250]));
}
```

Solution file — generate it with the SDK (do not hand-write GUIDs), from the fixture directory:
```bash
(cd evals/fixtures/dotnet && dotnet new sln -n Billing && dotnet sln Billing.sln add src/Billing/Billing.csproj src/Web/Web.csproj tests/Billing.Tests/Billing.Tests.csproj)
```
Commit the generated `Billing.sln` as is.

`evals/fixtures/dotnet/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| OrderService.OrderTotalLabel | src/Billing/OrderService.cs | Label an order total | `(IEnumerable<(long Cents, int Quantity)>) -> string` | 2 | pure |
| InvoiceService.AmountDueLabel | src/Billing/InvoiceService.cs | Label an invoice amount due | `(IEnumerable<long>) -> string` | 0 | pure |
```

`evals/fixtures/dotnet/.claude/reusable-dev.md`
```markdown
---
stack: dotnet
ui_lib: ""
shared_paths:
  components: src/Web/Components/Shared
  functions: src/Shared
commands:
  typecheck: ""
  lint: ""
  test: "dotnet test"
  build: ""
  e2e: ""
error_style: throw
registry: docs/reuse-registry.md
skills:
  design: []
  test: []
  verify: []
  debug: []
  review: []
  plan: []
  e2e: []
---
Fixture project. A .NET 8 solution: domain logic in src/Billing, API and Blazor components in src/Web, xunit tests in tests/Billing.Tests.
```

**Probe variants (spec §6.4):** only the env variant ✓ → set `test: 'DOTNET_CLI_HOME="$PWD/.dotnet-home" DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 dotnet test'`; both ✗ → set `test: ""`.

- [ ] **Step 2: Verify the fixture on the host**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/dotnet/. "$tmp" && (cd "$tmp" && dotnet test 2>&1 | grep -E "Passed!|Failed!|error|warning")
git status --porcelain evals/fixtures
```
Expected: `Passed!  - Failed:     0, Passed:     2`, no `error`/`warning` lines; git status lists only new source files (no `bin/`, `obj/`).

- [ ] **Step 3: Create the eval cases**

`evals/14-rule-of-three-dotnet/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" dotnet
```

`evals/14-rule-of-three-dotnet/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-dotnet
description: .NET — a third money-formatting need extracts the duplicated private helper to shared code and keeps dotnet tests green.
tags: [phase2c, dotnet]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Add a BalanceLabel(Customer customer) method to a new CustomerService class in src/Billing/CustomerService.cs that returns text like "Balance: $12.50" from customer.BalanceCents, with an xunit test in tests/Billing.Tests/CustomerServiceTests.cs.'
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: '(^|\n)src/(Shared|Billing\.Shared|Billing/Shared|Billing/Common)/[^\n]*\.cs'
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: src/Billing/OrderService.cs }
    pattern: 'string FormatMoney\('
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: src/Billing/InvoiceService.cs }
    pattern: 'string FormatMoney\('
    match: not_contains
  - type: regex
    name: customers-no-local-copy
    target: { source: file, path: src/Billing/CustomerService.cs }
    pattern: 'string FormatMoney\('
    match: not_contains
  - type: regex
    name: customers-uses-shared
    target: { source: file, path: src/Billing/CustomerService.cs }
    pattern: '\w+\.(Format|ToMoney)\w*\(|using Billing\.(Shared|Common)\b'
  - type: regex
    name: tests-green
    target: trace
    pattern: 'Passed!\s+-\s+Failed:\s+0,\s+Passed:\s+(?:[3-9]|\d{2,})'
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: tests/Billing.Tests/OrderServiceTests.cs }
    pattern: 'Order total: \$25\.00'
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: tests/Billing.Tests/InvoiceServiceTests.cs }
    pattern: 'Amount due: \$3\.50'
  - type: regex
    name: reports-create
    pattern: 'Reuse decision:\s*Create'
    flags: i
  - type: tool_used
    name: skill-fired
    tool: Skill
    input_match: "reusable-dev"
```

**Probe fallback (both variants ✗):** replace the `tests-green` grader with these two graders and change the description's "keeps dotnet tests green" to "reports T2 skipped (dotnet is unavailable in the eval sandbox)":
```yaml
  - type: regex
    name: reports-t2-skipped
    pattern: 'Verified:[^\n]*T2 skipped'
  - type: regex
    name: shared-wired
    target: trace
    pattern: 'ProjectReference Include=\\?"[^"\\]*Shared[^"\\]*\.csproj|src/Billing/(Shared|Common)/'
```

`evals/15-setup-detects-dotnet/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" dotnet --no-config
```

`evals/15-setup-detects-dotnet/case.yaml`
```yaml
schema_version: "1.0"
name: 15-setup-detects-dotnet
description: /reuse-setup detects the dotnet stack despite a tooling package.json, with the dotnet test command (graded on the write attempt; the eval sandbox denies .claude/** writes).
tags: [phase2c, dotnet]
context:
  scaffold_script: setup.sh
execution:
  prompt: "/reusable-dev:reuse-setup  (non-interactive: accept all detected defaults, leave unknown extension points empty)"
  max_turns: 30
  allowed_tools: [Read, Glob, Grep, Bash, Write, Edit]
graders:
  - type: tool_used
    name: attempted-config-write
    tool: Write
    input_match: 'reusable-dev\.md'
    min: 1
  - type: tool_used
    name: config-has-dotnet
    tool: Write
    input_match: 'stack:\s*dotnet'
    min: 1
  - type: tool_used
    name: config-has-dotnet-test-command
    tool: Write
    input_match: 'test:\s*\\?"?dotnet test'
    min: 1
  - type: tool_used
    name: no-bash-config-workaround
    tool: Bash
    input_match: 'reusable-dev\.md'
    min: 0
    max: 0
```

`chmod +x` both setup.sh files.

- [ ] **Step 4: Research and write `dotnet.md`**

Sources: learn.microsoft.com — aspnet/core/fundamentals (dependency-injection, configuration/options, minimal-apis route groups, error-handling `IExceptionHandler`), aspnet/core/blazor/components (parameters, templated components / `RenderFragment`, splatting `CaptureUnmatchedValues`, `@ref`, data binding `@bind-Value`, class libraries RCL), dotnet/core/testing (unit testing with xUnit, `dotnet test --filter`), aspnet/core/test/integration-tests (`WebApplicationFactory`). Fill every `_template.md` section. Content:
- Detection: `*.sln` at the root, or `*.csproj` at the root or in `src/*/` (detection row 9). `*.fsproj` only → ecosystem `fsharp` (general rules).
- Reuse units: class library per domain (`src/<Domain>`); services registered in DI; extension methods; minimal API endpoint groups (`MapGroup`) or controllers; Razor components with parameters; Razor class libraries (RCL) for shared UI.
- Paths: `src/<App>.Api` or `src/Web` (endpoints, components) → `src/<Domain>` (pure logic, no ASP.NET references) → `src/Shared`; SDK-style projects include every `.cs` file under the project folder, a new shared project needs `dotnet sln add` and a `ProjectReference`; shared components in `Components/Shared` or an RCL. Skip `bin/`, `obj/`.
- Component idioms: C3 `[Parameter] public ButtonVariant Variant` enum mapped to CSS classes (short example); C4 `ChildContent` `RenderFragment` + named `RenderFragment` parameters; C5 `[Parameter(CaptureUnmatchedValues = true)] public Dictionary<string, object>? AdditionalAttributes` + `@attributes`, refs via `@ref` / `ElementReference`; C6 controlled `Value` + `ValueChanged` `EventCallback<T>` (`@bind-Value`), uncontrolled = internal field with an initial value.
- Logic idioms: F2 constructor injection (primary constructors allowed), registration in `Program.cs` (`builder.Services.AddScoped<IShipmentTracker, ShipmentTracker>()`), `IOptions<T>` for settings (short example); F6 domain exceptions mapped once by an `IExceptionHandler` to `ProblemDetails` / `TypedResults.Problem`, or a `Result<T>` type when `error_style: result`.
- Testing: xUnit / NUnit / MSTest; `dotnet test --filter FullyQualifiedName~<Name>`; API tests with `WebApplicationFactory<Program>`; component tests with bUnit when the project already has it; use exactly config `commands.test`; if it is empty, run no test command and report `T2 skipped (no command)` (commands above are examples for filling the config).
- Anti-patterns: business logic in endpoints/controllers or `@code` blocks; injecting `IServiceProvider` to resolve services (service locator); `.Result` / `.Wait()` and `async void` outside event handlers; copy-pasted components instead of parameters / `RenderFragment`.

- [ ] **Step 5: Validate**

Run:
```bash
wc -l skills/reusable-dev/references/stacks/dotnet.md
claude plugin validate . --strict
grep -rn "FormatMoney\|format_money\|formatMoney\|OrderService\|InvoiceService\|CustomerService\|BalanceLabel\|balanceLabel\|OrderSummary\|OrderTotalLabel\|AmountDueLabel" skills commands agents
python3 -c "import yaml,re; [re.compile(g.get('pattern') or g.get('input_match') or '.') for f in ['evals/14-rule-of-three-dotnet/case.yaml','evals/15-setup-detects-dotnet/case.yaml'] for g in yaml.safe_load(open(f))['graders']]; print('yaml ok')"
```
Expected: ≤ 150; validation passed; grep prints nothing; `yaml ok`.

- [ ] **Step 6: Commit**

```bash
git add skills/reusable-dev/references/stacks/dotnet.md evals/fixtures/dotnet evals/14-rule-of-three-dotnet evals/15-setup-detects-dotnet
git commit -m "feat: add dotnet stack reference with evals"
```

- [ ] **Step 7: Evals (implementer runs both, one per command)**

```bash
evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-dotnet
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-dotnet
```
Expected: with-plugin 1.00 for both. A with-plugin score below 1.00: report the failing grader with the result JSON explanation (`evals/results/<run>/aggregate-result.json`); do not rerun or change files — the controller decides.

---

### Task 4: Phase 2c acceptance

**Files:**
- Modify: spec status line

- [ ] **Step 1: Structural checks**

Run:
```bash
claude plugin validate . --strict
wc -l skills/reusable-dev/SKILL.md skills/reusable-dev/references/*.md skills/reusable-dev/references/stacks/*.md
git diff --stat cf4defa -- skills/reusable-dev/SKILL.md
claude --plugin-dir . plugin details reusable-dev | sed -n '/Projected token cost/,/Per-component/p'
grep -rn "FormatMoney\|format_money\|formatMoney\|OrderService\|InvoiceService\|CustomerService\|BalanceLabel\|balanceLabel\|OrderSummary\|OrderTotalLabel\|AmountDueLabel" skills commands agents
ls evals | grep -c probe
git status --porcelain evals/fixtures
```
Expected: validation passed; every reference ≤ 150 lines; SKILL.md diff empty; always-on cost ≈ 761 tokens; grep prints nothing; probe count `0`; fixtures clean.

- [ ] **Step 2: Rerun the two new cases (controller, one per command)**

```bash
evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-dotnet
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-dotnet
```
Expected: with-plugin 1.00 for both.

- [ ] **Step 3: Mark the spec implemented and commit**

In the spec change `- **สถานะ:** Approved design, รอรีวิว spec` to `- **สถานะ:** Implemented (phase 2c)`.

```bash
git add docs/superpowers/specs/2026-09-15-reusable-dev-phase2c-design.md
git commit -m "docs: mark phase 2c spec implemented"
```
