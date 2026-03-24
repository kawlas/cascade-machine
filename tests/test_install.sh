#!/bin/bash
set -euo pipefail

OUTPUT=$(./install.sh --dry-run)

[[ "$OUTPUT" == *"./scripts/heal.sh"* ]]
[[ "$OUTPUT" == *"./docs/INSTALL.md"* ]]
[[ "$OUTPUT" == *"./.cascade/commands.md"* ]]
[[ "$OUTPUT" == *"/Users/oldspice/.cascade/docs/COMMANDS.md"* ]]
[[ "$OUTPUT" == *"Instalacja zakończona"* ]]
