#!/bin/bash
set -euo pipefail

OUTPUT=$(bash -lc 'source scripts/lib/router_core.sh && tier_bonus local')

[[ "$OUTPUT" == "-25" ]]
