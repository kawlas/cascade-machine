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
printf 'base\n' > "$TMP_REPO/app.txt"
git -C "$TMP_REPO" add app.txt
git -C "$TMP_REPO" commit -qm "init"

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
fixture	fixture/model-a	openai/model-a	free	200000	https://api.fixture.test/v1	FIXTURE_API_KEY
fixture	fixture/model-b	openai/model-b	free	200000	https://api.fixture.test/v1	FIXTURE_API_KEY
EOF

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/bash
set -euo pipefail

OUTPUT=""
DATA=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) OUTPUT="$2"; shift 2 ;;
        -d) DATA="$2"; shift 2 ;;
        -w) shift 2 ;;
        -H|--connect-timeout|--max-time) shift 2 ;;
        -s|-S|-sS|-fsSL|-fsS|-fsSLk) shift ;;
        *) shift ;;
    esac
done

[ -n "$OUTPUT" ] && printf '{"ok":true}\n' > "$OUTPUT"
case "$DATA" in
    *model-a*) printf '503' ;;
    *) printf '200' ;;
esac
EOF
chmod +x "$TMP_DIR/curl"

cat > "$TMP_DIR/aider" <<'EOF'
#!/bin/bash
set -euo pipefail

MODEL_LOG="${CASCADE_FAKE_AIDER_MODEL_LOG:?}"
REPO_DIR="${CASCADE_FAKE_REPO_DIR:?}"
model=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --model) model="$2"; shift 2 ;;
        *) shift ;;
    esac
done

printf '%s\n' "$model" >> "$MODEL_LOG"
printf 'fixed by %s\n' "$model" >> "$REPO_DIR/app.txt"
git -C "$REPO_DIR" add app.txt
git -C "$REPO_DIR" commit -qm "fix"
exit 0
EOF
chmod +x "$TMP_DIR/aider"

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
        CASCADE_MODEL_HEALTH_FILE="$TMP_DIR/health.tsv" \
        CASCADE_MODEL_HEALTH_ENABLED=true \
        CASCADE_MODEL_HEALTH_TTL_SECONDS=3600 \
        CASCADE_MODEL_HEALTH_PROBE_LIMIT=2 \
        CASCADE_FAKE_AIDER_MODEL_LOG="$TMP_DIR/models.log" \
        CASCADE_FAKE_REPO_DIR="$TMP_REPO" \
        FIXTURE_API_KEY=test \
        OLLAMA_HOST=http://127.0.0.1:9 \
        bash -c 'cd "$TMP_REPO" && source "$REPO_ROOT/scripts/lib/heal_core.sh" && run_heal "implement fix" --provider fixture' \
)

[[ "$OUTPUT" == *"SUCCESS: fixture/model-b"* ]]
grep -Fxq "openai/model-b" "$TMP_DIR/models.log"
! grep -Fxq "openai/model-a" "$TMP_DIR/models.log"
grep -q $'^fixture/model-a\t' "$TMP_DIR/health.tsv"
grep -q $'^fixture/model-b\t' "$TMP_DIR/health.tsv"
