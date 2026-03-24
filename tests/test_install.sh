#!/bin/bash
set -euo pipefail

TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
touch "$TEST_HOME/.zshrc"

OUTPUT=$(HOME="$TEST_HOME" ./install.sh --dry-run)

[[ "$OUTPUT" == *"./scripts/heal.sh"* ]]
[[ "$OUTPUT" == *"./scripts/lib/router_core.sh"* ]]
[[ "$OUTPUT" == *"./docs/INSTALL.md"* ]]
[[ "$OUTPUT" == *"./.cascade/commands.md"* ]]
[[ "$OUTPUT" == *"$TEST_HOME/.cascade/docs/COMMANDS.md"* ]]
[[ "$OUTPUT" == *"Instalacja zakończona"* ]]
