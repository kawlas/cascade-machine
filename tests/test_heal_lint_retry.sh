#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TMP_REPO="$TMP_DIR/repo"
mkdir -p "$TMP_REPO"
git init -q "$TMP_REPO"
git -C "$TMP_REPO" config user.email "cascade@example.com"
git -C "$TMP_REPO" config user.name "CASCADE Tests"
printf 'package\n' > "$TMP_REPO/app.txt"
printf 'ruff\n' > "$TMP_REPO/requirements.txt"
git -C "$TMP_REPO" add app.txt requirements.txt
git -C "$TMP_REPO" commit -qm "init"

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
EOF

cat > "$TMP_DIR/aider" <<'EOF'
#!/bin/bash
set -euo pipefail

REPO_DIR="${CASCADE_FAKE_REPO_DIR:?}"
COUNT_FILE="${CASCADE_FAKE_AIDER_COUNT_FILE:?}"
count=0
[ -f "$COUNT_FILE" ] && count="$(cat "$COUNT_FILE")"
count=$((count + 1))
printf '%s' "$count" > "$COUNT_FILE"
printf 'attempt %s\n' "$count" >> "$REPO_DIR/app.txt"
git -C "$REPO_DIR" add app.txt
git -C "$REPO_DIR" commit -qm "attempt $count"
exit 0
EOF
chmod +x "$TMP_DIR/aider"

cat > "$TMP_DIR/ruff" <<'EOF'
#!/bin/bash
set -euo pipefail

COUNT_FILE="${CASCADE_FAKE_RUFF_COUNT_FILE:?}"
count=0
[ -f "$COUNT_FILE" ] && count="$(cat "$COUNT_FILE")"
count=$((count + 1))
printf '%s' "$count" > "$COUNT_FILE"
if [ "$count" -eq 1 ]; then
    echo "E999 lint failed" >&2
    exit 1
fi
exit 0
EOF
chmod +x "$TMP_DIR/ruff"

OUTPUT=$(
    env \
        PATH="$TMP_DIR:$PATH" \
        REPO_ROOT="$REPO_ROOT" \
        TMP_REPO="$TMP_REPO" \
        CASCADE_HOME="$TMP_DIR/home" \
        CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
        CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
        CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
        CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
        CASCADE_MODEL_HEALTH_ENABLED=false \
        CASCADE_FAKE_REPO_DIR="$TMP_REPO" \
        CASCADE_FAKE_AIDER_COUNT_FILE="$TMP_DIR/aider-count.txt" \
        CASCADE_FAKE_RUFF_COUNT_FILE="$TMP_DIR/ruff-count.txt" \
        OPENROUTER_API_KEY=test \
        OLLAMA_HOST=http://127.0.0.1:9 \
        bash -c 'cd "$TMP_REPO" && source "$REPO_ROOT/scripts/lib/heal_core.sh" && run_heal "implement fix"' \
)

[[ "$OUTPUT" == *"SUCCESS: openrouter/model-a"* ]]
[[ "$(cat "$TMP_DIR/aider-count.txt")" == "2" ]]
[[ "$(cat "$TMP_DIR/ruff-count.txt")" == "3" ]]
