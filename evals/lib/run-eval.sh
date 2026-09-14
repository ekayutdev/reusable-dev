#!/bin/bash
# Run the plugin eval suite with ~/.docker moved aside.
# The eval Bash sandbox refuses to start while ~/.docker contains symlinks
# (Docker Desktop installs some), so the directory is stashed for the run
# and always restored. Docker CLI commands fail while an eval is running.
set -euo pipefail

docker_dir="$HOME/.docker"
stash="$HOME/.docker.eval-stash"

restore() {
  [[ -e "$stash" ]] || return 0
  if [[ -e "$docker_dir" ]]; then
    # Something recreated ~/.docker during the run; keep it instead of nesting.
    mv "$docker_dir" "$docker_dir.recreated.$(date +%s)"
  fi
  mv "$stash" "$docker_dir"
}

if [[ "${1:-}" == "--restore" ]]; then
  restore
  exit 0
fi

if [[ -e "$stash" ]]; then
  echo "run-eval: $stash exists — an earlier run did not restore it." >&2
  echo "run-eval: run evals/lib/run-eval.sh --restore to put it back" >&2
  echo "run-eval: this is unsafe while another eval is running" >&2
  exit 1
fi

if [[ -e "$docker_dir" ]]; then
  mv "$docker_dir" "$stash"
  trap restore EXIT
  trap 'exit 130' INT TERM HUP
fi

cd "$(dirname "$0")/../.."
claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Write Edit \
  --judge-model sonnet --no-publish "$@"
