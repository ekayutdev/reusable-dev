<!-- researched 2026-09-15: laravel/framework@12.x (laravel.com/docs/12.x/blade, /container, /providers, /validation, /eloquent, /errors, /testing), pest@3.x (pestphp.com/docs/filtering-tests) -->

# Stack: laravel

Laravel backend (Eloquent, Blade, service container). No language core file — the general rules plus this reference apply.

## Detection
`artisan`, or `laravel/framework` in `composer.json` (detection row 6). A `package.json` with only Vite/Tailwind tooling does not change the stack. Inertia apps: map UI paths to `react-next` / `vue-nuxt` with a stack path map. Livewire is out of scope — general rules.

## Reuse units
- Action class: one public `handle()` (or `__invoke()`) per file in `app/Actions`, resolved by the service container — the unit of reusable business logic.
- Service class: a named domain service in `app/Services`, resolved by the container, collaborators injected via the constructor.
- Eloquent local scope: a `#[Scope]` method on the model that constrains a query, chainable by name (laravel.com/docs/12.x/eloquent, Query Scopes → Local Scopes).
- Form Request: a class in `app/Http/Requests` with `authorize()` / `rules()` encapsulating reusable validation (laravel.com/docs/12.x/validation, Form Request Validation).
- Blade component: anonymous (one file in `resources/views/components`) or class component in `app/View/Components` (laravel.com/docs/12.x/blade, Components / Anonymous Components).

## Paths
- Actions `app/Actions`; services `app/Services`; pure helpers `app/Support` — no facades, no container.
- Views `resources/views`; shared components `resources/views/components`, class components `app/View/Components`.
- Skip `vendor/`, `storage/`, `bootstrap/cache/` — generated or framework code, never a reuse source.

## Component idioms
- C3 variants: one component with a `variant` prop, not per-look copies. Anonymous component (laravel.com/docs/12.x/blade, Data Properties / Attributes):
```blade
@props(['variant' => 'solid'])
<button {{ $attributes->merge(['class' => 'btn btn-'.$variant]) }}>
    {{ $slot }}
</button>
```
Called as `<x-button variant="outline">Save</x-button>` — the caller's `class` merges with the defaults (laravel.com/docs/12.x/blade, Component Attributes).
- C4: default content is `{{ $slot }}`; named slots via `<x-slot:title>` (laravel.com/docs/12.x/blade, Slots).
- C5: forward caller attributes on the root element with `{{ $attributes }}` — merge defaults, never drop them.
- C6: a controlled input carries `name` and `value` / `old('field', $default)`; uncontrolled takes the default attribute only.
- No copy-and-tweak components (`button_danger.blade.php` beside `button.blade.php`); C7: variants map to classes, no hardcoded colors.

## Logic idioms
- F2: constructor injection — type-hint collaborators and the container autowires concrete classes (laravel.com/docs/12.x/container, Zero Configuration Resolution):
```php
final class ShipmentScheduler
{
    public function __construct(private CarrierGateway $carriers) {}

    public function schedule(Shipment $shipment): void
    {
        // ...
    }
}
```
- Bind interfaces to implementations in a service provider's `register()` (laravel.com/docs/12.x/providers, The Register Method):
```php
public function register(): void
{
    $this->app->bind(CarrierGateway::class, HttpCarrierGateway::class);
}
```
- F6: services throw domain exceptions; render/report them in `bootstrap/app.php` `->withExceptions(...)` (laravel.com/docs/12.x/errors, Handling Exceptions):
```php
->withExceptions(function (Exceptions $exceptions): void {
    $exceptions->render(function (ShipmentTooLate $e, Request $request) {
        return response()->json(['error' => $e->getMessage()], 422);
    });
})
```
- Pure helpers: `final` classes or plain functions with typed signatures in `app/Support` — no facades, unit-testable without booting Laravel.

## Testing
- Pest or PHPUnit, both shipped out of the box (laravel.com/docs/12.x/testing).
- One file: `php artisan test tests/Feature/ShipmentTest.php` or `vendor/bin/pest tests/Unit/DateRangeTest.php` (pestphp.com/docs/filtering-tests).
- Use exactly what config `commands.test` specifies.

## Stack-specific anti-patterns
- Fat controllers — parse and delegate; logic goes to an Action or service.
- Logic in Blade templates — a template renders, it does not compute.
- Facades inside domain services — hard to test; inject the contract instead.
- Copy-and-tweak components — one component with a `variant` and `$attributes->merge`.
