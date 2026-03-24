#!/bin/bash
set -euo pipefail

TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
touch "$TEST_HOME/.zshrc"

HOME="$TEST_HOME" ./install.sh >/dev/null

OUTPUT=$(HOME="$TEST_HOME" bash "$TEST_HOME/.cascade/help.sh" sync)

[[ "$OUTPUT" == *"Synchronizuje runtime z repo"* ]]
[[ -f "$TEST_HOME/.cascade/.install-source" ]]
[[ "$(cat "$TEST_HOME/.cascade/.install-source")" == "$(pwd)" ]]
