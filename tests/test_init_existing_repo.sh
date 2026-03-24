#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
git init -q
echo "notes" > README.md
git add README.md
git commit -m "docs: seed repo" -q

bash /Users/oldspice/Documents/PROJEKTY/MOJ\ WORKFLOW/scripts/init-project.sh . --python >/dev/null

[[ -f .cascade/commands.md ]]
LAST_MESSAGE=$(git log -1 --pretty=%s)
[[ "$LAST_MESSAGE" == "docs: seed repo" ]]
