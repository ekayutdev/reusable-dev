#!/bin/bash
# Copy an eval fixture into the current eval workspace.
set -euo pipefail
name="${1:?fixture name required}"
src="$(cd "$(dirname "$0")/../fixtures/$name" && pwd)"
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "use-fixture: refusing to copy into a non-empty directory $(pwd)" >&2
  exit 1
fi
cp -R "$src/." .
if [[ "${2:-}" == "--no-config" ]]; then
  rm -f .claude/reusable-dev.md
fi
