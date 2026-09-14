#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" node-ts
sed -i.bak 's/^  test: \[\]$/  test: [acme-missing:super-tdd-x]/' .claude/reusable-dev.md
rm .claude/reusable-dev.md.bak
grep -q 'acme-missing:super-tdd-x' .claude/reusable-dev.md
