#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

bash scripts/init-project.sh "$WORKDIR/sample-app" --python > /dev/null

[[ -f "$WORKDIR/sample-app/AGENTS.md" ]]
[[ -f "$WORKDIR/sample-app/.aider.conf.yml" ]]
[[ -f "$WORKDIR/sample-app/.cascade/commands.md" ]]
[[ -f "$WORKDIR/sample-app/.cascade/decisions.md" ]]
grep -q "CASCADE —" "$WORKDIR/sample-app/.cascade/commands.md"
grep -q "test-cmd: python -m pytest -x -q" "$WORKDIR/sample-app/.aider.conf.yml"
