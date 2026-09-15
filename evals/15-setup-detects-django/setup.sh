#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" django --no-config
