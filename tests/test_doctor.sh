#!/bin/bash
set -euo pipefail

OUTPUT=$(bash scripts/help.sh /doctor)

[[ "$OUTPUT" == *"CASCADE doctor"* ]]
[[ "$OUTPUT" == *"runtime files"* ]]
[[ "$OUTPUT" == *"shell integration"* ]]
[[ "$OUTPUT" == *"quick"* ]]
[[ "$OUTPUT" == *"cloud"* ]]
