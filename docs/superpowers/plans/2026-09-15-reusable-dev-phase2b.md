# reusable-dev Phase 2b (Laravel, Rust axum, SwiftUI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `laravel`, `rust-axum`, `swiftui` stack support to the reusable-dev plugin: detection, Discover roots, one reference file per stack, a runnable offline fixture per stack, and two eval cases per stack.

**Architecture:** One self-contained reference per stack (no language core file this round). Detection rows 6–8 are inserted before the bare UI-library and generic package.json rows in `references/config-format.md`, so Laravel's Vite `package.json` never makes a project node-ts. Each fixture runs its tests with the local toolchain only: Laravel through a plain-PHP assert runner, Rust through a workspace that excludes the axum crate, SwiftUI through a SwiftPM package. A first probe task proves the eval sandbox can run `cargo` and `swift`.

**Tech Stack:** Claude Code plugin (Markdown), `claude plugin eval` via `evals/lib/run-eval.sh`, PHP 8.3 CLI, Rust 1.98.1 (`cargo test --offline`), Swift 6.3 (`swift test`, Swift Testing).

**Spec:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md`

## Global Constraints

- Do not install, uninstall, or upgrade software (no brew, composer install/require, cargo add/install, rustup, pecl, npm). Fixtures run offline with the existing `php`, `cargo`, `swift`. Laravel fixture code must not import `Illuminate\*`; the Rust fixture's only dependency-bearing crate (`crates/api`) stays excluded from the workspace.
- Run fixture tests only in a temporary copy, never inside `evals/fixtures/` (build output would be copied into every eval run): `tmp=$(mktemp -d) && cp -R evals/fixtures/<name>/. "$tmp" && (cd "$tmp" && <command>)`. `git status --porcelain evals/fixtures` must never list `target/`, `.build/` or `Cargo.lock`.
- Run evals only via `evals/lib/run-eval.sh` (it stashes `~/.docker`); one case per run; `--runs 1`. After each run: `ls -d ~/.docker` exists and `~/.docker.eval-stash` does not; otherwise run `evals/lib/run-eval.sh --restore` and stop. Never restart a stopped eval on your own.
- References: ≤ 150 lines, English, section order of `stacks/_template.md`, first line `<!-- researched 2026-09-15: <lib>@<version>, … -->` from official docs (laravel.com/docs, docs.rs/axum, developer.apple.com/documentation/swiftui, docs.swift.org). No `Read <core>.md first.` line — these stacks have no language core.
- SKILL.md unchanged. Report prefixes `Reuse decision:` / `Verified:` / `Notes:`, ladder, tiers T1–T4, seven extension points unchanged.
- New `stack` values exactly: `laravel`, `rust-axum`, `swiftui`. Ecosystem names without a reference: `go | php | rust | swift`.
- Grader rules: `tool_used` with `max: 0` also needs `min: 0`; the trace stores tool output JSON-escaped; tests-green graders count ≥ 3 tests (fixture has 2, the task adds 1): laravel `OK (?:[3-9]|\d{2,}) tests`, rust `test result: ok\. (?:[3-9]|\d{2,}) passed`, swift `Test run with (?:[3-9]|\d{2,}) tests? in \d+ suites? passed`.
- Never put a fixture file/function/class name or grader string into shipped plugin files (`skills/`, `commands/`, `agents/`). Leak list: `formatMoney`, `format_money`, `orderTotalLabel`, `order_total_label`, `amountDueLabel`, `amount_due_label`, `balanceLabel`, `balance_label`, `OrderService`, `InvoiceService`, `CustomerService`, `OrderLabel`, `InvoiceLabel`, `CustomerLabel`.
- YAML: write prompts and regex patterns containing backslashes as single-quoted scalars (`'…'`); a literal `'` inside is `''`.
- Every setup.sh starts with `#!/bin/bash` and `set -euo pipefail`, is executable, and calls `"$(dirname "$0")/../lib/use-fixture.sh" <fixture> [--no-config]`.
- Commit after every task. Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
  ```

**Ruling (plan vs spec):** spec §6.1 gives the swift grader as `with (?:[3-9]|\d{2,}) tests? .* passed`. Swift 6.3 prints `✔ Test run with 2 tests in 0 suites passed after 0.001 seconds.` (verified 2026-09-15), and `.*` could bridge a failed run to a later `passed` on the same escaped trace line, so the plan uses the anchored form above.

---

## File Structure

```
.gitignore                                                 Task 1 (fixture build output)
evals/fixtures/toolchain-probe/**                          Task 1
evals/00b-harness-toolchains/{case.yaml,setup.sh}          Task 1
docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md   Task 1 (probe result), Task 6 (status)
skills/reusable-dev/references/config-format.md            Task 2 (detection rows 6–8, commands, roots, shared paths)
commands/reuse-setup.md                                    Task 2 (ecosystem names in step 2)
README.md                                                  Task 2 (stacks line)
skills/reusable-dev/references/stacks/laravel.md           Task 3
evals/fixtures/laravel/**                                  Task 3
evals/14-rule-of-three-laravel/, evals/15-setup-detects-laravel/     Task 3
skills/reusable-dev/references/stacks/rust-axum.md         Task 4
evals/fixtures/rust-axum/**                                Task 4
evals/14-rule-of-three-rust-axum/, evals/15-setup-detects-rust-axum/ Task 4
skills/reusable-dev/references/stacks/swiftui.md           Task 5
evals/fixtures/swiftui/**                                  Task 5
evals/14-rule-of-three-swiftui/, evals/15-setup-detects-swiftui/     Task 5
```

---

### Task 1: Sandbox toolchain probe

**Files:**
- Modify: `.gitignore`
- Create: `evals/fixtures/toolchain-probe/probe-rust/Cargo.toml`, `evals/fixtures/toolchain-probe/probe-rust/src/lib.rs`
- Create: `evals/fixtures/toolchain-probe/probe-swift/Package.swift`, `evals/fixtures/toolchain-probe/probe-swift/Sources/Probe/Probe.swift`, `evals/fixtures/toolchain-probe/probe-swift/Tests/ProbeTests/ProbeTests.swift`
- Create: `evals/00b-harness-toolchains/{case.yaml,setup.sh}`
- Modify: spec §6.4 (append the probe result)

**Interfaces:**
- Produces: a `Probe result` line in spec §6.4 stating, for `cargo`, `swift`, `php`, which command works inside the eval sandbox. Tasks 3–5 read it: `cargo test --offline` ✓ / ✗; `swift test` ✓, or `swift test --disable-sandbox` ✓, or ✗; `php` ✓ / ✗.

- [ ] **Step 1: Ignore fixture build output**

Append to `.gitignore`:
```
evals/fixtures/**/target/
evals/fixtures/**/.build/
evals/fixtures/**/Cargo.lock
```

- [ ] **Step 2: Create the probe fixture**

`evals/fixtures/toolchain-probe/probe-rust/Cargo.toml`
```toml
[package]
name = "probe"
version = "0.1.0"
edition = "2021"
```

`evals/fixtures/toolchain-probe/probe-rust/src/lib.rs`
```rust
pub fn probe() -> &'static str {
    "ok"
}

#[cfg(test)]
mod tests {
    #[test]
    fn probe_runs() {
        assert_eq!(super::probe(), "ok");
    }
}
```

`evals/fixtures/toolchain-probe/probe-swift/Package.swift`
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Probe",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Probe"),
        .testTarget(name: "ProbeTests", dependencies: ["Probe"]),
    ]
)
```

`evals/fixtures/toolchain-probe/probe-swift/Sources/Probe/Probe.swift`
```swift
import SwiftUI

public func probe() -> String {
    "ok"
}

public struct ProbeView: View {
    public init() {}

    public var body: some View {
        Text(probe())
    }
}
```

`evals/fixtures/toolchain-probe/probe-swift/Tests/ProbeTests/ProbeTests.swift`
```swift
import Testing
@testable import Probe

@Test func probeRuns() {
    #expect(probe() == "ok")
}
```

- [ ] **Step 3: Verify the probe fixture outside the sandbox**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/toolchain-probe/. "$tmp" && (cd "$tmp/probe-rust" && cargo test --offline) && (cd "$tmp/probe-swift" && swift test) && php --version
git status --porcelain evals/fixtures
```
Expected: `test result: ok. 1 passed`; `Test run with 1 test in 0 suites passed`; `PHP 8.3.x`; git status lists only the new source files.

- [ ] **Step 4: Create the probe case**

`evals/00b-harness-toolchains/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" toolchain-probe
```

`evals/00b-harness-toolchains/case.yaml`
```yaml
schema_version: "1.0"
name: 00b-harness-toolchains
description: The eval sandbox can run cargo, swift and php for the phase 2b fixtures.
tags: [harness]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Run these four commands with the Bash tool, one Bash call each, exactly as written, and report the exit code of each: `(cd probe-rust && cargo test --offline)`, `(cd probe-swift && swift test)`, `(cd probe-swift && swift test --disable-sandbox)`, `php --version`. Do not edit any file.'
  max_turns: 10
  allowed_tools: [Bash, Read]
runs: 1
graders:
  - type: regex
    name: rust-tests
    target: trace
    pattern: 'test result: ok\. 1 passed'
  - type: regex
    name: swift-tests
    target: trace
    pattern: 'Test run with 1 test in \d+ suites? passed'
  - type: regex
    name: php-runs
    target: trace
    pattern: 'PHP 8\.\d+\.\d+'
```

`chmod +x evals/00b-harness-toolchains/setup.sh`

- [ ] **Step 5: Run the probe and read the trace**

Run: `evals/lib/run-eval.sh --runs 1 --case 00b-harness-toolchains --keep-temp`
Then read `<kept>/out/trace.jsonl` read-only and note, for each of the four commands, its exit code and the first error line if any (e.g. `command not found`, `sandbox-exec: sandbox_apply: Operation not permitted`, a permission-denied path).

Decide per toolchain:
- `cargo`: `cargo test --offline` ✓ if its output has `test result: ok. 1 passed`, else ✗.
- `swift`: `swift test` ✓ if it passed; else `swift test --disable-sandbox` ✓ if that passed; else ✗.
- `php`: ✓ if `PHP 8.` appears, else ✗.

A ✗ is a valid result, not a task failure. Do not change sandbox settings, PATH, or `run-eval.sh` to make a command pass.

- [ ] **Step 6: Record the result in the spec**

Append to the end of spec §6.4 (after the paragraph starting `Verify inside`), with the observed values filled in:
```markdown

**Probe result (2026-09-15, `evals/00b-harness-toolchains`):** cargo `cargo test --offline` <✓|✗: first error line>; swift <`swift test` ✓ | `swift test --disable-sandbox` ✓ | ✗: first error line>; php <✓|✗: first error line>.
```

- [ ] **Step 7: Commit**

```bash
git add .gitignore evals/fixtures/toolchain-probe evals/00b-harness-toolchains docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md
git commit -m "test: probe cargo, swift and php inside the eval sandbox"
```

---

### Task 2: Detection rows, commands, source roots

**Files:**
- Modify: `skills/reusable-dev/references/config-format.md`
- Modify: `commands/reuse-setup.md` (step 2 only)
- Modify: `README.md` (Stacks line)

**Interfaces:**
- Produces: detection rows 6 `laravel`, 7 `rust-axum`, 8 `swiftui`; `commands.test` rules for PHP/Rust/Swift; source roots and shared paths for PHP/Rust/Swift. Used by Tasks 3–5 and cases 15-*.

- [ ] **Step 1: Replace the detection section**

In `config-format.md`, replace everything from the line `Python web frameworks (rows 4–5) come before` through the table row `| – | Multiple \`apps/*\` or \`packages/*\` with different signals | path map for \`stack\` |` with:

```markdown
Backend and native frameworks (rows 4–8) come before bare UI-library deps (row 9) and generic package.json rows (10–11) because those projects often keep a package.json only for asset tooling (Vite, Tailwind).

| # | Signal | Value |
|---|---|---|
| 1 | `next.config.*` or `"next"` in package.json deps | `stack: react-next` |
| 2 | `nuxt.config.*` or `"nuxt"` in deps | `stack: vue-nuxt` |
| 3 | `"@sveltejs/kit"` in deps (with or without `svelte.config.*`) | `stack: sveltekit` |
| 4 | `manage.py`, or `django` in `pyproject.toml` / `requirements*.txt` | `stack: django` |
| 5 | `fastapi` in `pyproject.toml` / `requirements*.txt` | `stack: fastapi` |
| 6 | `artisan`, or `laravel/framework` in `composer.json` | `stack: laravel` |
| 7 | `axum` in any `Cargo.toml` in the repo (root, member, or excluded crate) | `stack: rust-axum` |
| 8 | `Package.swift` or `*.xcodeproj` present and `import SwiftUI` in a source file | `stack: swiftui` |
| 9 | `"react"` in deps without next → `stack: react-next`; `"vue"` in deps without nuxt → `stack: vue-nuxt` | see signal |
| 10 | `"@nestjs/core"` in deps or `nest-cli.json` | `stack: nestjs` |
| 11 | package.json with another server framework (`express`, `fastify`, `hono`) or no UI framework, and no `pyproject.toml` / `requirements*.txt` / `setup.py` / `composer.json` / `Cargo.toml` / `Package.swift` at the same level (tsconfig.json optional) | `stack: node-ts` |
| 12 | other `pyproject.toml` / `requirements*.txt` / `setup.py` | `stack: python` |
| – | `components.json` + react / vue / svelte | `ui_lib: shadcn-react` / `shadcn-vue` / `shadcn-svelte` |
| – | package.json `scripts` named `typecheck`/`type-check`, `lint`, `test`, `build`, `e2e`/`test:e2e` | `commands.*` = `<pm> run <script>` using the lockfile's package manager |
| – | Python: `pytest` in deps → `commands.test: pytest`; else `manage.py` → `python3 manage.py test`; else `python3 -m unittest` | `commands.test` |
| – | Laravel: `vendor/bin/pest` exists → `commands.test: vendor/bin/pest`; else `php artisan test` | `commands.test` |
| – | Rust: `cargo test` | `commands.test` |
| – | Swift: `Package.swift` → `swift test`; only `*.xcodeproj` → `xcodebuild test -scheme <scheme>` with a scheme from `xcodebuild -list`; scheme unknown → ask, non-interactive → `""` | `commands.test` |
| – | Multiple `apps/*` or `packages/*` with different signals | path map for `stack` |
```

- [ ] **Step 2: Update the allowed `stack` values**

Replace in the schema block:
```
# react-next | vue-nuxt | sveltekit | node-ts | nestjs | fastapi | django | python, or an ecosystem name (go | php, no reference file), or a path map for monorepos:
```
with:
```
# react-next | vue-nuxt | sveltekit | node-ts | nestjs | fastapi | django | python | laravel | rust-axum | swiftui, or an ecosystem name (go | php | rust | swift, no reference file), or a path map for monorepos:
```

- [ ] **Step 3: Extend source roots and shared paths**

In `## Source roots by language`, add three rows after the `| Python |` row:
```markdown
| PHP | `app/`, `src/`, `resources/views/components/`, `packages/*` | `vendor/`, `storage/`, `bootstrap/cache/`, `node_modules` |
| Rust | `src/`, `crates/*` | `target/` |
| Swift | `Sources/*`, `Packages/*`, the app target folder | `.build/`, `DerivedData/` |
```

After the paragraph starting `Python shared paths (first that exists`, add:
```markdown
Laravel shared paths (first that exists): functions `app/Support`, `app/Actions`; components `resources/views/components`. Rust: functions `crates/shared/src`, `src/shared`; components `""`. SwiftUI: functions `Sources/Shared`, `Packages/Shared/Sources`; components `Sources/DesignSystem`, `Packages/DesignSystem/Sources`.
```

- [ ] **Step 4: Update `commands/reuse-setup.md` step 2**

Replace:
```
(read package.json, lockfiles, framework config files, components.json, tsconfig, go.mod/pyproject.toml/composer.json). Stacks outside the detection table: use the ecosystem name (`go` for go.mod, `php` for composer.json) and treat it as a stack without a reference file (step 4).
```
with:
```
(read package.json, lockfiles, framework config files, components.json, tsconfig, go.mod/pyproject.toml/composer.json/Cargo.toml/Package.swift). Stacks outside the detection table: use the ecosystem name (`go` for go.mod, `php` for composer.json without Laravel, `rust` for Cargo.toml without axum, `swift` for Package.swift or `*.xcodeproj` without SwiftUI) and treat it as a stack without a reference file (step 4).
```

- [ ] **Step 5: README stacks line**

Replace `Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript · NestJS · FastAPI · Django` with `Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript · NestJS · FastAPI · Django · Laravel · Rust (axum) · SwiftUI`.

- [ ] **Step 6: Validate**

Run: `claude plugin validate . --strict && wc -l skills/reusable-dev/references/config-format.md && git diff --stat`
Expected: validation passed; config-format.md ≤ 150 lines; diff touches only the three files.

- [ ] **Step 7: Regression evals**

Run one at a time:
```bash
evals/lib/run-eval.sh --runs 1 --case 01-extend-button-react
evals/lib/run-eval.sh --runs 1 --case 02-reuse-existing-function
evals/lib/run-eval.sh --runs 1 --case 04-rule-of-three
evals/lib/run-eval.sh --runs 1 --case 10-audit-reports-without-editing
evals/lib/run-eval.sh --runs 1 --case 11-setup-writes-config
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-django
```
Expected: with-plugin 1.00 for each. On a failure, rerun that case with `--keep-temp`, read `<kept>/out/trace.jsonl` read-only, and fix only wording changed in this task. Max 2 reruns per case.

- [ ] **Step 8: Commit**

```bash
git add skills/reusable-dev/references/config-format.md commands/reuse-setup.md README.md
git commit -m "feat: detect laravel, rust-axum and swiftui stacks"
```

---

### Task 3: Laravel (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/laravel.md`
- Create: `evals/fixtures/laravel/**` (Step 1)
- Create: `evals/14-rule-of-three-laravel/{case.yaml,setup.sh}`, `evals/15-setup-detects-laravel/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: detection row 6, Laravel `commands.test` rule, PHP roots and Laravel shared paths (Task 2); probe result for `php` (Task 1, spec §6.4).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/laravel/composer.json`
```json
{
    "name": "fixture/laravel-billing",
    "type": "project",
    "require": {
        "php": "^8.3",
        "laravel/framework": "^12.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    }
}
```

`evals/fixtures/laravel/artisan`
```php
#!/usr/bin/env php
<?php

use Illuminate\Foundation\Application;
use Symfony\Component\Console\Input\ArgvInput;

define('LARAVEL_START', microtime(true));

// Register the Composer autoloader...
require __DIR__.'/vendor/autoload.php';

// Bootstrap Laravel and handle the command...
/** @var Application $app */
$app = require_once __DIR__.'/bootstrap/app.php';

$status = $app->handleCommand(new ArgvInput);

exit($status);
```

`evals/fixtures/laravel/package.json`
```json
{
  "private": true,
  "type": "module",
  "devDependencies": { "laravel-vite-plugin": "^2.0.0", "tailwindcss": "^4.0.0", "vite": "^7.0.0" }
}
```

`evals/fixtures/laravel/app/Data/Customer.php`
```php
<?php

declare(strict_types=1);

namespace App\Data;

final readonly class Customer
{
    public function __construct(
        public string $id,
        public string $name,
        public int $balanceCents,
    ) {
    }
}
```

`evals/fixtures/laravel/app/Services/OrderService.php`
```php
<?php

declare(strict_types=1);

namespace App\Services;

class OrderService
{
    /** @param list<array{int, int}> $lines [cents, quantity] pairs */
    public function orderTotalLabel(array $lines): string
    {
        $total = array_sum(array_map(fn (array $line): int => $line[0] * $line[1], $lines));

        return 'Order total: ' . $this->formatMoney($total);
    }

    private function formatMoney(int $cents): string
    {
        return '$' . number_format($cents / 100, 2);
    }
}
```

`evals/fixtures/laravel/app/Services/InvoiceService.php`
```php
<?php

declare(strict_types=1);

namespace App\Services;

class InvoiceService
{
    /** @param list<int> $amounts cents */
    public function amountDueLabel(array $amounts): string
    {
        return 'Amount due: ' . $this->formatMoney(array_sum($amounts));
    }

    private function formatMoney(int $cents): string
    {
        return '$' . number_format($cents / 100, 2);
    }
}
```

`evals/fixtures/laravel/tests/run.php`
```php
<?php

declare(strict_types=1);

// Minimal test runner: Laravel, PHPUnit and Pest are not installed in this project.
spl_autoload_register(function (string $class): void {
    $roots = ['App\\' => __DIR__ . '/../app/', 'Tests\\' => __DIR__ . '/'];
    foreach ($roots as $prefix => $dir) {
        if (str_starts_with($class, $prefix)) {
            $file = $dir . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
            if (is_file($file)) {
                require $file;
            }
            return;
        }
    }
});

$files = array_merge(glob(__DIR__ . '/Unit/*Test.php') ?: [], glob(__DIR__ . '/Feature/*Test.php') ?: []);
$count = 0;
$failures = [];

foreach ($files as $file) {
    $class = 'Tests\\' . str_replace('/', '\\', substr($file, strlen(__DIR__) + 1, -4));
    foreach (get_class_methods($class) as $method) {
        if (!str_starts_with($method, 'test')) {
            continue;
        }
        $count++;
        try {
            (new $class())->$method();
        } catch (Throwable $e) {
            $failures[] = "{$class}::{$method}: {$e->getMessage()}";
        }
    }
}

if ($failures !== []) {
    echo 'FAILURES ' . count($failures) . " of {$count} tests\n" . implode("\n", $failures) . "\n";
    exit(1);
}

echo "OK {$count} tests\n";
```

`evals/fixtures/laravel/tests/TestCase.php`
```php
<?php

declare(strict_types=1);

namespace Tests;

abstract class TestCase
{
    protected function assertSame(mixed $expected, mixed $actual): void
    {
        if ($expected !== $actual) {
            throw new \RuntimeException('Expected ' . var_export($expected, true) . ', got ' . var_export($actual, true));
        }
    }
}
```

`evals/fixtures/laravel/tests/Unit/OrderServiceTest.php`
```php
<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\OrderService;
use Tests\TestCase;

class OrderServiceTest extends TestCase
{
    public function testSumsLines(): void
    {
        $this->assertSame('Order total: $25.00', (new OrderService())->orderTotalLabel([[1000, 2], [500, 1]]));
    }
}
```

`evals/fixtures/laravel/tests/Unit/InvoiceServiceTest.php`
```php
<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\InvoiceService;
use Tests\TestCase;

class InvoiceServiceTest extends TestCase
{
    public function testSumsAmounts(): void
    {
        $this->assertSame('Amount due: $3.50', (new InvoiceService())->amountDueLabel([100, 250]));
    }
}
```

`evals/fixtures/laravel/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| OrderService::orderTotalLabel | app/Services/OrderService.php | Label an order total | `(array $lines): string` | 0 | pure |
| InvoiceService::amountDueLabel | app/Services/InvoiceService.php | Label an invoice amount due | `(array $amounts): string` | 0 | pure |
```

`evals/fixtures/laravel/.claude/reusable-dev.md`
```markdown
---
stack: laravel
ui_lib: ""
shared_paths:
  components: resources/views/components
  functions: app/Support
commands:
  typecheck: ""
  lint: ""
  test: "php tests/run.php"
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
Fixture project for reusable-dev evals. Laravel is not installed (no vendor/); services are plain PHP and tests run with commands.test.
```

**Probe fallback:** if spec §6.4 records `php` ✗, set `test: ""` in the config above.

- [ ] **Step 2: Verify the fixture**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/laravel/. "$tmp" && (cd "$tmp" && php tests/run.php)
git status --porcelain evals/fixtures
```
Expected: `OK 2 tests`, exit 0; only new source files listed.

- [ ] **Step 3: Create the eval cases**

`evals/14-rule-of-three-laravel/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" laravel
```

`evals/14-rule-of-three-laravel/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-laravel
description: Laravel — a third money-formatting need extracts the duplicated private helper to a shared support class and keeps tests green.
tags: [phase2b, laravel]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Add a balanceLabel(Customer $customer): string method to a new App\Services\CustomerService class in app/Services/CustomerService.php that returns text like "Balance: $12.50" from $customer->balanceCents (App\Data\Customer), with a test in tests/Unit/CustomerServiceTest.php.'
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: '(^|\n)app/(Support|Actions)/[^\n]*\.php'
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: app/Services/OrderService.php }
    pattern: 'function formatMoney'
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: app/Services/InvoiceService.php }
    pattern: 'function formatMoney'
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: app/Services/CustomerService.php }
    pattern: 'App\\(Support|Actions)\\'
  - type: regex
    name: tests-green
    target: trace
    pattern: 'OK (?:[3-9]|\d{2,}) tests'
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: tests/Unit/OrderServiceTest.php }
    pattern: 'Order total: \$25\.00'
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: tests/Unit/InvoiceServiceTest.php }
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

**Probe fallback:** if spec §6.4 records `php` ✗, replace the `tests-green` grader with:
```yaml
  - type: regex
    name: reports-t2-skipped
    pattern: 'Verified:[^\n]*T2 skipped'
```

`evals/15-setup-detects-laravel/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" laravel --no-config
```

`evals/15-setup-detects-laravel/case.yaml`
```yaml
schema_version: "1.0"
name: 15-setup-detects-laravel
description: /reuse-setup detects Laravel despite the tooling package.json, with the artisan test command (graded on the write attempt; the eval sandbox denies .claude/** writes).
tags: [phase2b, laravel]
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
    name: config-has-laravel
    tool: Write
    input_match: 'stack:\s*laravel'
    min: 1
  - type: tool_used
    name: config-has-artisan-test-command
    tool: Write
    input_match: 'test:\s*\\?"?php artisan test'
    min: 1
  - type: tool_used
    name: no-bash-config-workaround
    tool: Bash
    input_match: 'reusable-dev\.md'
    min: 0
    max: 0
```

`chmod +x` both setup.sh files.

- [ ] **Step 4: RED run**

Run: `evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-laravel` then `evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-laravel`
Record both tables (RED: `laravel.md` not written yet; case 15 may already pass from Task 2 detection — record either way).

- [ ] **Step 5: Research and write `laravel.md`**

Sources: laravel.com/docs (Blade components, service container, service providers, validation/Form Requests, Eloquent local scopes, errors, testing), pestphp.com/docs. Fill every `_template.md` section. Content:
- Detection: `artisan`, or `laravel/framework` in `composer.json` (detection row 6). Inertia apps: map UI paths to `react-next` / `vue-nuxt` with a stack path map; Livewire is out of scope (general rules).
- Reuse units: Action classes (one public `handle`/`__invoke`) and Service classes resolved by the service container; Eloquent local scopes; Form Requests for reusable validation; Blade anonymous components (`resources/views/components`) and class components (`app/View/Components`).
- Paths: `app/Actions`, `app/Services`, `app/Support` (pure helpers, no facades); `resources/views/components` (+ `app/View/Components` for class components). Skip `vendor/`, `storage/`, `bootstrap/cache/`.
- Component idioms: C3 `variant` prop via `@props([...])` + `$attributes->merge(['class' => …])` (short Blade example); C4 default `$slot` + named `<x-slot:name>`; C5 `$attributes` forwarded to the root element; C6 controlled value via `value`/`old('field', $default)` + `name`, uncontrolled via default attribute only.
- Logic idioms: F2 constructor injection (container autowiring), bind interfaces in a service provider `register()` (short example); F6 domain exceptions thrown by services and rendered/reported in `bootstrap/app.php` `->withExceptions(...)`; pure helpers as static-free final classes or plain functions with typed signatures.
- Testing: Pest or PHPUnit; single file `php artisan test tests/Feature/XTest.php` or `vendor/bin/pest tests/Unit/XTest.php`; use exactly config `commands.test`.
- Anti-patterns: fat controllers; logic in Blade templates; facades inside domain services (hard to test — inject the contract); copy-and-tweak components instead of `$attributes`/variants.

- [ ] **Step 6: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/laravel.md && claude plugin validate . --strict`
Run both laravel cases once each (one per run). Expected: with-plugin 1.00 for both. On failure: rerun with `--keep-temp`, read the trace, tighten the reference wording (graders only when provably wrong, with quoted trace evidence). Max 2 reruns per case.

- [ ] **Step 7: Commit**

```bash
git add skills/reusable-dev/references/stacks/laravel.md evals/fixtures/laravel evals/14-rule-of-three-laravel evals/15-setup-detects-laravel
git commit -m "feat: add laravel stack reference with evals"
```

---

### Task 4: Rust axum (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/rust-axum.md`
- Create: `evals/fixtures/rust-axum/**` (Step 1)
- Create: `evals/14-rule-of-three-rust-axum/{case.yaml,setup.sh}`, `evals/15-setup-detects-rust-axum/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: detection row 7, Rust `commands.test` rule, Rust roots and shared paths (Task 2); probe result for `cargo` (Task 1, spec §6.4).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/rust-axum/Cargo.toml`
```toml
[workspace]
resolver = "2"
members = ["crates/billing"]
# crates/api needs axum and tokio from crates.io; it is excluded so tests run offline.
exclude = ["crates/api"]
```

`evals/fixtures/rust-axum/crates/api/Cargo.toml`
```toml
[package]
name = "api"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.8"
billing = { path = "../billing" }
tokio = { version = "1", features = ["full"] }
```

`evals/fixtures/rust-axum/crates/api/src/main.rs`
```rust
use axum::{routing::get, Router};

async fn order_total() -> String {
    billing::orders::order_total_label(&[(1000, 2), (500, 1)])
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/orders/total", get(order_total));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
```

`evals/fixtures/rust-axum/crates/billing/Cargo.toml`
```toml
[package]
name = "billing"
version = "0.1.0"
edition = "2021"
```

`evals/fixtures/rust-axum/crates/billing/src/lib.rs`
```rust
pub mod customers;
pub mod invoices;
pub mod orders;
```

`evals/fixtures/rust-axum/crates/billing/src/orders.rs`
```rust
fn format_money(cents: i64) -> String {
    format!("${}.{:02}", cents / 100, cents % 100)
}

pub fn order_total_label(lines: &[(i64, i64)]) -> String {
    let total: i64 = lines.iter().map(|(cents, qty)| cents * qty).sum();
    format!("Order total: {}", format_money(total))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sums_lines() {
        assert_eq!(order_total_label(&[(1000, 2), (500, 1)]), "Order total: $25.00");
    }
}
```

`evals/fixtures/rust-axum/crates/billing/src/invoices.rs`
```rust
fn format_money(cents: i64) -> String {
    format!("${}.{:02}", cents / 100, cents % 100)
}

pub fn amount_due_label(amounts: &[i64]) -> String {
    format!("Amount due: {}", format_money(amounts.iter().sum()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sums_amounts() {
        assert_eq!(amount_due_label(&[100, 250]), "Amount due: $3.50");
    }
}
```

`evals/fixtures/rust-axum/crates/billing/src/customers.rs`
```rust
pub struct Customer {
    pub id: String,
    pub name: String,
    pub balance_cents: i64,
}
```

`evals/fixtures/rust-axum/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| order_total_label | crates/billing/src/orders.rs | Label an order total | `(&[(i64, i64)]) -> String` | 1 | pure |
| amount_due_label | crates/billing/src/invoices.rs | Label an invoice amount due | `(&[i64]) -> String` | 0 | pure |
```

`evals/fixtures/rust-axum/.claude/reusable-dev.md`
```markdown
---
stack: rust-axum
ui_lib: ""
shared_paths:
  components: ""
  functions: crates/shared/src
commands:
  typecheck: ""
  lint: ""
  test: "cargo test --offline"
  build: ""
  e2e: ""
error_style: result
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
Fixture project for reusable-dev evals. The workspace excludes crates/api (axum is not in the offline cargo cache); tests run for workspace members only.
```

**Probe fallback:** if spec §6.4 records `cargo` ✗, set `test: ""` in the config above.

- [ ] **Step 2: Verify the fixture**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/rust-axum/. "$tmp" && (cd "$tmp" && cargo test --offline)
git status --porcelain evals/fixtures
```
Expected: `test result: ok. 2 passed` for `billing`, no attempt to download axum; only new source files listed.

- [ ] **Step 3: Create the eval cases**

`evals/14-rule-of-three-rust-axum/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" rust-axum
```

`evals/14-rule-of-three-rust-axum/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-rust-axum
description: Rust axum — a third money-formatting need extracts the duplicated helper to a shared crate or module and keeps cargo tests green.
tags: [phase2b, rust-axum]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Add a pub fn balance_label(customer: &Customer) -> String in crates/billing/src/customers.rs that returns text like "Balance: $12.50" from customer.balance_cents, with a unit test in the same file.'
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: '(^|\n)(crates/shared/src/[^\n]*\.rs|crates/billing/src/(money|shared)[^\n]*\.rs)'
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: crates/billing/src/orders.rs }
    pattern: 'fn format_money'
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: crates/billing/src/invoices.rs }
    pattern: 'fn format_money'
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: crates/billing/src/customers.rs }
    pattern: '(crate|super)::(money|shared)\b|\bshared::'
  - type: regex
    name: tests-green
    target: trace
    pattern: 'test result: ok\. (?:[3-9]|\d{2,}) passed'
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: crates/billing/src/orders.rs }
    pattern: 'Order total: \$25\.00'
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: crates/billing/src/invoices.rs }
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

**Probe fallback:** if spec §6.4 records `cargo` ✗, replace the `tests-green` grader with:
```yaml
  - type: regex
    name: reports-t2-skipped
    pattern: 'Verified:[^\n]*T2 skipped'
```

`evals/15-setup-detects-rust-axum/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" rust-axum --no-config
```

`evals/15-setup-detects-rust-axum/case.yaml`
```yaml
schema_version: "1.0"
name: 15-setup-detects-rust-axum
description: /reuse-setup detects rust-axum from an excluded workspace crate and the cargo test command (graded on the write attempt; the eval sandbox denies .claude/** writes).
tags: [phase2b, rust-axum]
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
    name: config-has-rust-axum
    tool: Write
    input_match: 'stack:\s*rust-axum'
    min: 1
  - type: tool_used
    name: config-has-cargo-test-command
    tool: Write
    input_match: 'test:\s*\\?"?cargo test'
    min: 1
  - type: tool_used
    name: no-bash-config-workaround
    tool: Bash
    input_match: 'reusable-dev\.md'
    min: 0
    max: 0
```

`chmod +x` both setup.sh files.

- [ ] **Step 4: RED run**

Run: `evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-rust-axum` then `evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-rust-axum`
Record both tables (RED: `rust-axum.md` not written yet; case 15 may already pass — record either way).

- [ ] **Step 5: Research and write `rust-axum.md`**

Sources: docs.rs/axum (Router, State, extractors, error handling, `IntoResponse`), docs.rs/thiserror, doc.rust-lang.org/cargo (workspaces), doc.rust-lang.org/book (modules, testing), docs.rs/tower (`ServiceExt::oneshot`). Fill every `_template.md` section. Content:
- Detection: `axum` in any `Cargo.toml` in the repo (detection row 7). Other `Cargo.toml` → ecosystem `rust` (general rules).
- Reuse units: workspace crates by domain (`crates/<domain>`), modules by domain inside a crate, traits for collaborators, domain error enums converted with `IntoResponse`, custom extractors.
- Paths: `crates/api` (axum router, handlers, extractors) depends on `crates/<domain>` (pure logic, no axum); shared helpers in `crates/shared` (add to workspace `members`, depend via `path`), or a shared module inside one crate when only that crate uses it. Skip `target/`.
- Component idioms: `Not applicable — no UI`.
- Logic idioms: F2 handlers receive `State<AppState>` holding `Arc<dyn Trait + Send + Sync>` or generic services (short example); domain functions pure and synchronous where possible; F6 domain `enum` errors (`thiserror`) returned as `Result<T, DomainError>` and mapped by `impl IntoResponse for ApiError` (short example); `error_style: result` is the natural default.
- Testing: `cargo test -p <crate>`; one test `cargo test <name>`; unit tests in `#[cfg(test)] mod tests` beside the code; handler tests call the router with `tower::ServiceExt::oneshot`; use exactly config `commands.test`.
- Anti-patterns: business logic in handlers; `unwrap()`/`expect()` in request paths; global `static mut` or lazy singletons for services; one giant `utils.rs`; domain crates depending on axum.

- [ ] **Step 6: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/rust-axum.md && claude plugin validate . --strict`
Run both rust-axum cases once each (one per run). Expected: with-plugin 1.00 for both. Same failure handling as Task 3 Step 6.

- [ ] **Step 7: Commit**

```bash
git add skills/reusable-dev/references/stacks/rust-axum.md evals/fixtures/rust-axum evals/14-rule-of-three-rust-axum evals/15-setup-detects-rust-axum
git commit -m "feat: add rust-axum stack reference with evals"
```

---

### Task 5: SwiftUI (reference, fixture, evals)

**Files:**
- Create: `skills/reusable-dev/references/stacks/swiftui.md`
- Create: `evals/fixtures/swiftui/**` (Step 1)
- Create: `evals/14-rule-of-three-swiftui/{case.yaml,setup.sh}`, `evals/15-setup-detects-swiftui/{case.yaml,setup.sh}`

**Interfaces:**
- Consumes: detection row 8, Swift `commands.test` rule, Swift roots and SwiftUI shared paths (Task 2); probe result for `swift` (Task 1, spec §6.4).

- [ ] **Step 1: Create the fixture**

`evals/fixtures/swiftui/Package.swift`
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Billing",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Orders"),
        .target(name: "Invoices"),
        .target(name: "Customers"),
        .testTarget(name: "OrdersTests", dependencies: ["Orders"]),
        .testTarget(name: "InvoicesTests", dependencies: ["Invoices"]),
    ]
)
```

`evals/fixtures/swiftui/Sources/Orders/OrderLabel.swift`
```swift
import SwiftUI

func formatMoney(_ cents: Int) -> String {
    let sign = cents < 0 ? "-" : ""
    let value = abs(cents)
    return "\(sign)$\(value / 100).\(String(format: "%02d", value % 100))"
}

public func orderTotalLabel(_ lines: [(cents: Int, quantity: Int)]) -> String {
    let total = lines.reduce(0) { $0 + $1.cents * $1.quantity }
    return "Order total: \(formatMoney(total))"
}

public struct OrderTotalView: View {
    let lines: [(cents: Int, quantity: Int)]

    public init(lines: [(cents: Int, quantity: Int)]) {
        self.lines = lines
    }

    public var body: some View {
        Text(orderTotalLabel(lines))
    }
}
```

`evals/fixtures/swiftui/Sources/Invoices/InvoiceLabel.swift`
```swift
import SwiftUI

func formatMoney(_ cents: Int) -> String {
    let sign = cents < 0 ? "-" : ""
    let value = abs(cents)
    return "\(sign)$\(value / 100).\(String(format: "%02d", value % 100))"
}

public func amountDueLabel(_ amounts: [Int]) -> String {
    "Amount due: \(formatMoney(amounts.reduce(0, +)))"
}

public struct AmountDueView: View {
    let amounts: [Int]

    public init(amounts: [Int]) {
        self.amounts = amounts
    }

    public var body: some View {
        Text(amountDueLabel(amounts))
    }
}
```

`evals/fixtures/swiftui/Sources/Customers/Customer.swift`
```swift
public struct Customer: Sendable {
    public let id: String
    public let name: String
    public let balanceCents: Int

    public init(id: String, name: String, balanceCents: Int) {
        self.id = id
        self.name = name
        self.balanceCents = balanceCents
    }
}
```

`evals/fixtures/swiftui/Tests/OrdersTests/OrderLabelTests.swift`
```swift
import Testing
@testable import Orders

@Test func sumsLines() {
    #expect(orderTotalLabel([(cents: 1000, quantity: 2), (cents: 500, quantity: 1)]) == "Order total: $25.00")
}
```

`evals/fixtures/swiftui/Tests/InvoicesTests/InvoiceLabelTests.swift`
```swift
import Testing
@testable import Invoices

@Test func sumsAmounts() {
    #expect(amountDueLabel([100, 250]) == "Amount due: $3.50")
}
```

`evals/fixtures/swiftui/docs/reuse-registry.md`
```markdown
# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| orderTotalLabel | Sources/Orders/OrderLabel.swift | Label an order total | `(_ lines: [(cents: Int, quantity: Int)]) -> String` | 1 | pure |
| amountDueLabel | Sources/Invoices/InvoiceLabel.swift | Label an invoice amount due | `(_ amounts: [Int]) -> String` | 1 | pure |
```

`evals/fixtures/swiftui/.claude/reusable-dev.md`
```markdown
---
stack: swiftui
ui_lib: ""
shared_paths:
  components: Sources/DesignSystem
  functions: Sources/Shared
commands:
  typecheck: ""
  lint: ""
  test: "swift test"
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
Fixture project for reusable-dev evals. A SwiftPM package (macOS 14); each feature is its own target, and new targets must be declared in Package.swift.
```

**Probe variants:** if spec §6.4 records `swift test --disable-sandbox` ✓ (and plain `swift test` ✗), set `test: "swift test --disable-sandbox"`; if `swift` ✗, set `test: ""`.

- [ ] **Step 2: Verify the fixture**

Run:
```bash
tmp=$(mktemp -d) && cp -R evals/fixtures/swiftui/. "$tmp" && (cd "$tmp" && swift test)
git status --porcelain evals/fixtures
```
Expected: `✔ Test run with 2 tests in 0 suites passed`; only new source files listed.

- [ ] **Step 3: Create the eval cases**

`evals/14-rule-of-three-swiftui/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" swiftui
```

`evals/14-rule-of-three-swiftui/case.yaml`
```yaml
schema_version: "1.0"
name: 14-rule-of-three-swiftui
description: SwiftUI — a third money-formatting need extracts the duplicated helper to a shared SwiftPM target and keeps swift tests green.
tags: [phase2b, swiftui]
context:
  scaffold_script: setup.sh
execution:
  prompt: 'Add a public balanceLabel(_ customer: Customer) -> String function in Sources/Customers/CustomerLabel.swift that returns text like "Balance: $12.50" from customer.balanceCents, with a Swift Testing test in Tests/CustomersTests/CustomerLabelTests.swift.'
  max_turns: 40
  allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
graders:
  - type: regex
    name: shared-module-created
    target: files
    pattern: '(^|\n)Sources/Shared/[^\n]*\.swift'
  - type: regex
    name: orders-no-local-copy
    target: { source: file, path: Sources/Orders/OrderLabel.swift }
    pattern: 'func formatMoney'
    match: not_contains
  - type: regex
    name: invoices-no-local-copy
    target: { source: file, path: Sources/Invoices/InvoiceLabel.swift }
    pattern: 'func formatMoney'
    match: not_contains
  - type: regex
    name: imports-shared
    target: { source: file, path: Sources/Customers/CustomerLabel.swift }
    pattern: 'import Shared\b'
  - type: regex
    name: tests-green
    target: trace
    pattern: 'Test run with (?:[3-9]|\d{2,}) tests? in \d+ suites? passed'
  - type: regex
    name: orders-assertion-kept
    target: { source: file, path: Tests/OrdersTests/OrderLabelTests.swift }
    pattern: 'Order total: \$25\.00'
  - type: regex
    name: invoices-assertion-kept
    target: { source: file, path: Tests/InvoicesTests/InvoiceLabelTests.swift }
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

**Probe fallback:** if spec §6.4 records `swift` ✗, replace the `tests-green` grader with:
```yaml
  - type: regex
    name: reports-t2-skipped
    pattern: 'Verified:[^\n]*T2 skipped'
```

`evals/15-setup-detects-swiftui/setup.sh`
```bash
#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" swiftui --no-config
```

`evals/15-setup-detects-swiftui/case.yaml`
```yaml
schema_version: "1.0"
name: 15-setup-detects-swiftui
description: /reuse-setup detects SwiftUI from Package.swift plus a SwiftUI import, with the swift test command (graded on the write attempt; the eval sandbox denies .claude/** writes).
tags: [phase2b, swiftui]
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
    name: config-has-swiftui
    tool: Write
    input_match: 'stack:\s*swiftui'
    min: 1
  - type: tool_used
    name: config-has-swift-test-command
    tool: Write
    input_match: 'test:\s*\\?"?swift test'
    min: 1
  - type: tool_used
    name: no-bash-config-workaround
    tool: Bash
    input_match: 'reusable-dev\.md'
    min: 0
    max: 0
```

`chmod +x` both setup.sh files.

- [ ] **Step 4: RED run**

Run: `evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-swiftui` then `evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-swiftui`
Record both tables (RED: `swiftui.md` not written yet; case 15 may already pass — record either way).

- [ ] **Step 5: Research and write `swiftui.md`**

Sources: developer.apple.com/documentation/swiftui (View, ViewModifier, ButtonStyle, ViewBuilder, Binding, State, Environment, Observable, FocusState), developer.apple.com/documentation/testing, docs.swift.org/swiftpm (targets, `swift test --filter`). Fill every `_template.md` section. Content:
- Detection: `Package.swift` or `*.xcodeproj` plus `import SwiftUI` in a source file (detection row 8). Swift without SwiftUI → ecosystem `swift` (general rules).
- Reuse units: small `View` structs; `ViewModifier` + `View` extension; `ButtonStyle` / `LabelStyle`; `@Observable` models; Swift Package targets (`DesignSystem`, `Shared`) declared in `Package.swift` and imported by feature targets.
- Paths: `Sources/DesignSystem` (views, styles, modifiers), `Sources/Shared` (pure functions, no SwiftUI import), feature targets per domain; in Xcode apps, local packages under `Packages/`. Skip `.build/`, `DerivedData/`.
- Component idioms: C3 variants as an `enum` passed to a style (`.buttonStyle(.brand(.destructive))`, short example); C4 content via `@ViewBuilder` closure parameters; C5 no refs — callers apply modifiers, focus via a `FocusState<…>.Binding` parameter; C6 controlled = `Binding<Value>` parameter, uncontrolled = internal `@State` with an initial value.
- Logic idioms: F2 inject dependencies via initializer or `@Environment` values (short example of a custom `EnvironmentValues` entry with `@Entry`); F6 `throws` with typed domain errors (`throws(DomainError)` in Swift 6), views map errors to UI state; `public` API on shared targets.
- Testing: Swift Testing (`@Test`, `#expect`, `@Suite`); `swift test --filter <Suite or test>`; test view logic through models and pure functions, not view bodies; Xcode projects: `xcodebuild test -scheme <scheme>`; use exactly config `commands.test`.
- Anti-patterns: logic in `body`; copy-pasted modifier chains instead of a `ViewModifier`; `@ObservedObject`/`@Observable` models created inside a view's init instead of `@State` or injection; massive views; a shared target importing feature targets.

- [ ] **Step 6: GREEN**

Run: `wc -l skills/reusable-dev/references/stacks/swiftui.md && claude plugin validate . --strict`
Run both swiftui cases once each (one per run). Expected: with-plugin 1.00 for both. Same failure handling as Task 3 Step 6.

- [ ] **Step 7: Commit**

```bash
git add skills/reusable-dev/references/stacks/swiftui.md evals/fixtures/swiftui evals/14-rule-of-three-swiftui evals/15-setup-detects-swiftui
git commit -m "feat: add swiftui stack reference with evals"
```

---

### Task 6: Phase 2b acceptance

**Files:**
- Modify: `docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md` (status line only)

- [ ] **Step 1: Structural checks**

Run:
```bash
claude plugin validate . --strict
wc -l skills/reusable-dev/SKILL.md skills/reusable-dev/references/*.md skills/reusable-dev/references/stacks/*.md
git diff --stat 794774f -- skills/reusable-dev/SKILL.md
claude --plugin-dir . plugin details reusable-dev | sed -n '/Projected token cost/,/Per-component/p'
grep -rn "formatMoney\|format_money\|orderTotalLabel\|order_total_label\|amountDueLabel\|amount_due_label\|balanceLabel\|balance_label\|OrderService\|InvoiceService\|CustomerService\|OrderLabel\|InvoiceLabel\|CustomerLabel" skills commands agents
git status --porcelain evals/fixtures
```
Expected: validation passed; every reference ≤ 150 lines; SKILL.md diff empty; always-on cost ≈ 761 tokens; the grep prints nothing; git status clean.

- [ ] **Step 2: Rerun the six new cases**

Run one at a time:
```bash
evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-laravel
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-laravel
evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-rust-axum
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-rust-axum
evals/lib/run-eval.sh --runs 1 --case 14-rule-of-three-swiftui
evals/lib/run-eval.sh --runs 1 --case 15-setup-detects-swiftui
```
Expected: with-plugin 1.00 for all six. A run reporting sandbox `credential store` errors or a leftover `~/.docker.eval-stash`: run `evals/lib/run-eval.sh --restore` if needed and rerun only that case.

- [ ] **Step 3: Mark the spec implemented and commit**

In the spec, change `- **สถานะ:** Approved design, รอรีวิว spec` to `- **สถานะ:** Implemented (phase 2b)`.

```bash
git add docs/superpowers/specs/2026-09-15-reusable-dev-phase2b-design.md
git commit -m "docs: mark phase 2b spec implemented"
```
