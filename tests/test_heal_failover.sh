#!/bin/bash
set -euo pipefail

RATE_LIMIT_OUTPUT=$(bash -lc 'source scripts/lib/heal_core.sh && aider_failure_kind "The API provider has rate limited you. Try again later or check your quotas."')
AUTH_OUTPUT=$(bash -lc 'source scripts/lib/heal_core.sh && aider_failure_kind "Unauthorized: invalid api key"')
MODEL_OUTPUT=$(bash -lc 'source scripts/lib/heal_core.sh && aider_failure_kind "model unavailable right now"')

[[ "$RATE_LIMIT_OUTPUT" == "rate_limit" ]]
[[ "$AUTH_OUTPUT" == "auth" ]]
[[ "$MODEL_OUTPUT" == "model_unavailable" ]]
