#!/bin/bash
set -euo pipefail

OUTPUT=$(bash scripts/help.sh)

[[ "$OUTPUT" == *"quick"* ]]
[[ "$OUTPUT" == *"fast"* ]]
[[ "$OUTPUT" == *"smart"* ]]
[[ "$OUTPUT" == *"cascade doctor"* ]]
[[ "$OUTPUT" != *"plan-local"* ]]
[[ "$OUTPUT" != *"big"* ]]
