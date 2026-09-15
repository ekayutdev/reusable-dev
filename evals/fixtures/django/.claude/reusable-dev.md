---
stack: django
ui_lib: ""
shared_paths:
  components: common/templates
  functions: common
commands:
  typecheck: ""
  lint: ""
  test: "python3 -m unittest discover"
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
Fixture project for reusable-dev evals. Django is not installed; tests cover plain-Python services only.
