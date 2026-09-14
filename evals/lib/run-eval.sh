#!/bin/bash
# Run the plugin eval suite with ~/.docker moved aside.
# The eval Bash sandbox refuses to start while ~/.docker contains symlinks
# (Docker Desktop installs some), so the directory is stashed for the run
# and always restored. Docker CLI commands fail while an eval is running.
set -euo pipefail

docker_dir="$HOME/.docker"
stash="$HOME/.docker.eval-stash"

if [[ -e "$stash" ]]; then
  echo "run-eval: $stash exists — an earlier run did not restore it." >&2
  echo "run-eval: restore it first: mv \"$stash\" \"$docker_dir\"" >&2
  exit 1
fi

restore() {
  [[ -e "$stash" ]] || return 0
  if [[ -e "$docker_dir" ]]; then
    # Something recreated ~/.docker during the run; keep it instead of nesting.
    mv "$docker_dir" "$docker_dir.recreated.$(date +%s)"
  fi
  mv "$stash" "$docker_dir"
}

if [[ -e "$docker_dir" ]]; then
  mv "$docker_dir" "$stash"
  trap restore EXIT
  trap 'exit 130' INT TERM HUP
fi

cd "$(dirname "$0")/../.."
claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit \
  --judge-model sonnet --no-publish "$@"
