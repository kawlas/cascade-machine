#!/bin/bash
set -euo pipefail

QUICK=$(bash scripts/router.sh classify "fix typo in README")
REASON=$(bash scripts/router.sh classify "explain this auth bug")
TESTING=$(bash scripts/router.sh classify "add pytest coverage")

[[ "$QUICK" == "quick" ]]
[[ "$REASON" == "reason" ]]
[[ "$TESTING" == "test" ]]
