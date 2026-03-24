#!/bin/bash
set -euo pipefail

TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
mkdir -p "$TEST_HOME/bin"
touch "$TEST_HOME/.zshrc"

cat > "$TEST_HOME/bin/curl" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$TEST_HOME/bin/curl"

cat > "$TEST_HOME/bin/ollama" <<'EOF'
#!/bin/bash
if [ "$1" = "list" ]; then
    echo "NAME ID SIZE MODIFIED"
    echo "qwen3-coder abc 18GB now"
    exit 0
fi
exit 0
EOF
chmod +x "$TEST_HOME/bin/ollama"

cat > "$TEST_HOME/bin/aider" <<'EOF'
#!/bin/bash
echo "FAKE_AIDER $*"
EOF
chmod +x "$TEST_HOME/bin/aider"

HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" bash install.sh >/dev/null

BEST_OUTPUT=$(HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false OLLAMA_HOST=http://127.0.0.1:9 bash "$TEST_HOME/.cascade/router.sh" best "implement auth")
CHAT_OUTPUT=$(HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false OLLAMA_HOST=http://127.0.0.1:9 bash "$TEST_HOME/.cascade/help.sh" || true)

[[ "$BEST_OUTPUT" == "ollama_chat/qwen3-coder" ]]
[[ "$CHAT_OUTPUT" == *"CASCADE App"* ]]
[[ "$CHAT_OUTPUT" == *"model: ollama_chat/qwen3-coder"* ]]
[[ "$CHAT_OUTPUT" == *"FAKE_AIDER --model ollama_chat/qwen3-coder"* ]]
