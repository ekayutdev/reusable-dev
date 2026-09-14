#!/bin/bash
# Copy an eval fixture into the current eval workspace.
set -euo pipefail
name="${1:?fixture name required}"
src="$(cd "$(dirname "$0")/../fixtures/$name" && pwd)"
cp -R "$src/." .
if [[ "${2:-}" == "--no-config" ]]; then
  rm -f .claude/reusable-dev.md
fi
