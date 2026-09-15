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
Fixture project. The workspace excludes crates/api (axum is not in the offline cargo cache).
