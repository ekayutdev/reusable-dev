---
stack: rust-axum
ui_lib: ""
shared_paths:
  components: ""
  functions: crates/shared/src
commands:
  typecheck: ""
  lint: ""
  test: ""
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
Fixture project for reusable-dev evals. The workspace excludes crates/api (axum is not in the offline cargo cache); tests run for workspace members only. Tests are not run by evals because cargo is unavailable in the eval sandbox; run `cargo test --offline` locally.
