#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" react-shadcn
mv docs/reuse-registry.md docs/components-registry.md
sed -i.bak 's/| shadcn generated |/| shadcn generated REG-SENTINEL-8B |/' docs/components-registry.md && rm docs/components-registry.md.bak
sed -i.bak 's|^registry: docs/reuse-registry.md$|registry: docs/components-registry.md|' .claude/reusable-dev.md
rm .claude/reusable-dev.md.bak
grep -q '^registry: docs/components-registry.md$' .claude/reusable-dev.md
grep -q 'REG-SENTINEL-8B' docs/components-registry.md
