#!/bin/bash
set -euo pipefail

OUTPUT=$(bash scripts/aliases.sh --show)

[[ "$OUTPUT" == *"alias fast="* ]]
[[ "$OUTPUT" == *"alias quick="* ]]
[[ "$OUTPUT" == *"alias think="* ]]
[[ "$OUTPUT" == *"alias cloud="* ]]
[[ "$OUTPUT" == *"alias smart="* ]]
[[ "$OUTPUT" == *"alias heal="* ]]
[[ "$OUTPUT" == *'alias cascade-status="$HOME/.cascade/help.sh status"'* ]]
[[ "$OUTPUT" != *"plan-local"* ]]
