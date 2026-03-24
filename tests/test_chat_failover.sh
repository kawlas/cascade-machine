#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
groq	groq/model-b	groq/model-b	free	200000		GROQ_API_KEY
EOF

cat > "$TMP_DIR/aider" <<'EOF'
#!/bin/bash
COUNT_FILE="${CASCADE_FAKE_AIDER_COUNT_FILE:?}"
count=0
[ -f "$COUNT_FILE" ] && count="$(cat "$COUNT_FILE")"
count=$((count + 1))
printf '%s' "$count" > "$COUNT_FILE"
if [ "$count" -eq 1 ]; then
    echo "The API provider has rate limited you. Try again later."
    exit 2
fi
echo "chat ok on retry"
exit 0
EOF
chmod +x "$TMP_DIR/aider"

OUTPUT=$(env \
    PATH="$TMP_DIR:$PATH" \
    CASCADE_HOME="$TMP_DIR" \
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
    CASCADE_MODEL_HEALTH_FILE="$TMP_DIR/health.tsv" \
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
    CASCADE_MODEL_HEALTH_ENABLED=false \
    CASCADE_APP_DISABLE_TTY_CAPTURE=true \
    CASCADE_FAKE_AIDER_COUNT_FILE="$TMP_DIR/count.txt" \
    OPENROUTER_API_KEY=test \
    GROQ_API_KEY=test \
    OLLAMA_HOST=http://127.0.0.1:9 \
    bash scripts/help.sh "implement auth" || true)

[[ "$OUTPUT" == *"CASCADE App"* ]]
[[ "$OUTPUT" == *"CASCADE reroute:"* ]]
[[ "$OUTPUT" == *"New model: groq/model-b"* ]]
[[ "$OUTPUT" == *"chat ok on retry"* ]]
grep -q '"provider":"openrouter"' "$TMP_DIR/usage.jsonl"
grep -q '"success":false' "$TMP_DIR/usage.jsonl"
