---
stack: swiftui
ui_lib: ""
shared_paths:
  components: Sources/DesignSystem
  functions: Sources/Shared
commands:
  typecheck: ""
  lint: ""
  test: ""
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
Fixture project for reusable-dev evals. A SwiftPM package (macOS 14); each feature is its own target, and new targets must be declared in Package.swift. Tests are not run by evals because swift is unavailable in the eval sandbox; run `swift test` locally.
