#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" node-ts
sed -i.bak 's/^  test: \[\]$/  test: [nonexistent-plugin:super-tdd]/' .claude/reusable-dev.md
rm .claude/reusable-dev.md.bak
