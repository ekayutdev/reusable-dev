<!-- researched <YYYY-MM-DD>: <what was read> (<sources>) -->

First line of every stack file, and the only place its freshness is recorded. `<what was read>` is `pkg@version` for anything with a package version (`next@16.3.5, react@19.3.0`), or the release band or platform name when there is none (`ASP.NET Core 8/9/10`, `SwiftUI`). `<sources>` are the doc paths actually read, comma-separated, not a bare domain. Keep it one line and drop this paragraph when you copy the template. A file written from a project's own conventions rather than from documentation says so instead — `<!-- not researched: written from project conventions on <YYYY-MM-DD> -->` — because a `researched` line is a claim that those pages were read.

# Stack: <name>

## Detection
<files and dependencies that identify this stack>

## Reuse units
<what a reusable component / stateful logic unit / function / module is called here, with file naming>

## Paths
<conventional locations for primitives, patterns, hooks/composables, domain functions, services; server vs client code split>

## Component idioms
<how this stack expresses component-design.md rules C3–C6: variants, children/slots, rest props + ref, controlled/uncontrolled — short code>

## Logic idioms
<how function-design.md rules F2 and F6 look here: dependency injection pattern, typed errors / result type — short code>

## Testing
<test runner, component testing library, how to run tests for one file (needed for T2/T3), default commands>

## Stack-specific anti-patterns
<3–6 bullets>
