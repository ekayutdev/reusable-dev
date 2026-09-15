#!/bin/bash
set -euo pipefail
exec "$(dirname "$0")/../lib/use-fixture.sh" dotnet --no-config
