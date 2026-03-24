#!/bin/bash
set -euo pipefail

OUTPUT=$(bash scripts/help.sh dashboard)
HELP_OUTPUT=$(bash scripts/help.sh help)

[[ "$OUTPUT" == *"CASCADE Machine"* ]]
[[ "$OUTPUT" == *"default model:"* ]]
[[ "$OUTPUT" == *"Start here:"* ]]
[[ "$OUTPUT" == *'cascade "zadanie"'* ]]
[[ "$OUTPUT" == *'cascade run "zadanie"'* ]]
[[ "$OUTPUT" == *"Maintenance:"* ]]
[[ "$HELP_OUTPUT" == *"Daily shortcuts:"* ]]
[[ "$HELP_OUTPUT" == *"Automatic self-healing:"* ]]
[[ "$HELP_OUTPUT" == *"cascade dashboard"* ]]
[[ "$HELP_OUTPUT" == *'cascade run "zadanie"'* ]]
[[ "$HELP_OUTPUT" == *"cascade doctor"* ]]
[[ "$HELP_OUTPUT" != *"plan-local"* ]]
[[ "$HELP_OUTPUT" != *"big"* ]]
