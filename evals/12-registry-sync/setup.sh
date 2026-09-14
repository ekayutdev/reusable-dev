#!/bin/bash
set -euo pipefail
"$(dirname "$0")/../lib/use-fixture.sh" react-shadcn
mkdir -p src/shared/lib
cat > src/shared/lib/format-date.ts <<'EOF'
export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}
EOF
grep -q 'export function formatDate' src/shared/lib/format-date.ts
