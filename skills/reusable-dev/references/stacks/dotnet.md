<!-- researched 2026-09-15: ASP.NET Core 8/9/10 (learn.microsoft.com/aspnet/core/fundamentals: dependency-injection, configuration/options, minimal-apis, error-handling IExceptionHandler; /aspnet/core/blazor/components: templated components, attribute splatting CaptureUnmatchedValues, @ref, data binding @bind-Value, class-libraries RCL; /aspnet/core/test/integration-tests: WebApplicationFactory), .NET SDK 8.0.203 (learn.microsoft.com/dotnet/core/testing: unit-testing-csharp-with-xunit, selective-unit-tests --filter), xunit 2.4.2, xunit.runner.visualstudio 2.4.5, Microsoft.NET.Test.Sdk 17.6.0 -->
# Stack: dotnet

ASP.NET Core minimal APIs plus Blazor components on .NET 8+. No language core file — the general rules plus this reference apply.

## Detection
`*.sln` / `*.slnx` at the root, or `*.csproj` at the root, in `*/` or in `src/*/`, with at least one `*.csproj` (detection row 9; `.slnx` is the `dotnet new sln` default from the .NET 10 SDK). A `package.json` with only asset tooling (Vite, Tailwind) does not change the stack. `*.fsproj` only → ecosystem `fsharp` (general rules). A React/Vue client beside the API (e.g. `*.client/package.json` or `src/Api/*.csproj` next to a root React app) → use a stack path map, e.g. `{ "src/Api": dotnet, "client": react-next }`.

## Reuse units
- Class library per domain: `src/<Domain>` with the domain's records and services — the unit of reusable business logic.
- Service class: registered in DI and constructor-injected; one concern per file (`ShipmentTracker.cs`).
- Extension method: a reusable helper on an existing type, `static class ShipmentExtensions` with `static ... Method(this ...)` (learn.microsoft.com/aspnet/core/fundamentals/dependency-injection, Service lifetimes and extension methods).
- Minimal API endpoint group: `app.MapGroup("/shipments")` with shared prefix/filters, or a controller — one file per endpoint family (learn.microsoft.com/aspnet/core/fundamentals/minimal-apis, Route groups).
- Razor component: a `.razor` file with `[Parameter]` properties, reused by composition.
- Razor class library (RCL): a separate project holding shared components and static assets (learn.microsoft.com/aspnet/core/blazor/components/class-libraries).

## Paths
- `src/<App>.Api` or `src/Web` — endpoints, `Program.cs`, `Components/`; never a reuse source for domain logic.
- `src/<Domain>` — pure logic, no ASP.NET package references.
- `src/Shared` — cross-domain helpers; shared components in `src/Web/Components/Shared` or an RCL.
- SDK-style projects include every `.cs` file under the project folder — a file dropped into `src/<Domain>/Shared/` compiles with no wiring; a new shared *project* needs `dotnet sln add` plus a `ProjectReference` in the consuming `.csproj`.
- Skip `bin/`, `obj/` — build output, never a reuse source.

## Component idioms
- C3 variants: one component with an enum parameter mapped to CSS classes, not per-look copies:
```razor
@code {
    [Parameter, EditorRequired] public ButtonVariant Variant { get; set; }
}
<button class="btn btn-@(Variant is ButtonVariant.Primary ? "primary" : "ghost")">@ChildContent</button>
```
- C4 content: `ChildContent` is the default slot; named `RenderFragment` parameters for extra slots (learn.microsoft.com/aspnet/core/blazor/components/templated-components):
```razor
<span>@ChildContent @if (Label is not null) { <small>@Label</small> }</span>
@code {
    [Parameter] public RenderFragment? ChildContent { get; set; }
    [Parameter] public RenderFragment? Label { get; set; }
}
```
- C5 splatting + ref: `[Parameter(CaptureUnmatchedValues = true)] public Dictionary<string, object>? AdditionalAttributes` forwarded with `@attributes="AdditionalAttributes"`; refs via `@ref` on the element and an `ElementReference` field (learn.microsoft.com/aspnet/core/blazor/components/attribute-splatting).
- C6 controlled/uncontrolled: controlled = `Value` + `ValueChanged` (`EventCallback<T>`), bound by the caller with `@bind-Value`; uncontrolled = an internal field with an initial value (learn.microsoft.com/aspnet/core/blazor/components/data-binding).

## Logic idioms
- F2: constructor injection (primary constructors allowed); register interfaces in `Program.cs` (learn.microsoft.com/aspnet/core/fundamentals/dependency-injection):
```csharp
builder.Services.AddScoped<IShipmentTracker, ShipmentTracker>();
```
- Settings: one options class per concern, read via `IOptions<T>` (learn.microsoft.com/aspnet/core/fundamentals/configuration/options):
```csharp
builder.Services.Configure<ReportOptions>(builder.Configuration.GetSection("Reports"));
// consumer: IOptions<ReportOptions> options → options.Value
```
- F6: services throw domain exceptions; map them once with `IExceptionHandler` to `ProblemDetails` / `TypedResults.Problem`, not per endpoint (learn.microsoft.com/aspnet/core/fundamentals/error-handling). An `IExceptionHandler` runs only when registered: `builder.Services.AddExceptionHandler<T>()` + `AddProblemDetails()` and `app.UseExceptionHandler()`. With `error_style: result`, return a `Result<T>` type instead of throwing.

## Testing
- xUnit / NUnit / MSTest; `dotnet test` runs the solution (learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit).
- One class: `dotnet test --filter FullyQualifiedName~ShipmentTests` (learn.microsoft.com/dotnet/core/testing/selective-unit-tests).
- API tests: `WebApplicationFactory<Program>` with an in-memory TestServer (learn.microsoft.com/aspnet/core/test/integration-tests); it needs `public partial class Program { }` in `Program.cs` when it uses top-level statements. Component tests: bUnit, only when the project already has it.
- Use exactly what config `commands.test` specifies; if it is empty, run no test command and report `T2 skipped (no command)` (commands above are examples for filling the config).

## Stack-specific anti-patterns
- Business logic in endpoints/controllers or `@code` blocks — move to a service or pure function; handlers delegate.
- Injecting `IServiceProvider` to resolve services (service locator) — depend on the contract instead.
- `.Result` / `.Wait()` and `async void` outside event handlers — thread-pool starvation in ASP.NET Core, deadlocks in Blazor, crashes from async void; await all the way.
- Copy-pasted components instead of parameters / `RenderFragment` — one component with variants.
