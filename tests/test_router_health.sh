#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin"

cat > "$TMP_DIR/bin/curl" <<'EOF'
#!/bin/bash
set -euo pipefail

OUTPUT=""
WRITE_OUT=""
DATA=""
URL=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) OUTPUT="$2"; shift 2 ;;
        -w) WRITE_OUT="$2"; shift 2 ;;
        -d) DATA="$2"; shift 2 ;;
        -H|--connect-timeout|--max-time) shift 2 ;;
        -s|-S|-sS|-fsSL|-fsS|-fsSLk) shift ;;
        http*) URL="$1"; shift ;;
        *) shift ;;
    esac
done

[ -n "$OUTPUT" ] && printf '{"ok":true}\n' > "$OUTPUT"

case "$DATA" in
    *model-a*) printf '%s' "503" ;;
    *model-b*) printf '%s' "200" ;;
    *) printf '%s' "200" ;;
esac
EOF
chmod +x "$TMP_DIR/bin/curl"

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
openrouter	openrouter/model-b	openrouter/model-b	free	200000		OPENROUTER_API_KEY
EOF

cat > "$TMP_DIR/usage.jsonl" <<'EOF'
{"date":"2099-01-01","provider":"openrouter","model":"openrouter/model-a","task_type":"code","success":true,"ts":1}
EOF

HEALTH_ENV=(
    PATH="$TMP_DIR/bin:$PATH"
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl"
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl"
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv"
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false
    CASCADE_MODEL_HEALTH_FILE="$TMP_DIR/health.tsv"
    CASCADE_MODEL_HEALTH_ENABLED=true
    CASCADE_MODEL_HEALTH_TTL_SECONDS=3600
    CASCADE_MODEL_HEALTH_PROBE_LIMIT=2
    OPENROUTER_API_KEY=test
    OLLAMA_HOST=http://127.0.0.1:9
)

PROBE=$(env "${HEALTH_ENV[@]}" bash scripts/router.sh probe --provider openrouter "implement auth")
BEST=$(env "${HEALTH_ENV[@]}" bash scripts/router.sh best --provider openrouter "implement auth")
PLAN=$(env "${HEALTH_ENV[@]}" bash scripts/router.sh plan --provider openrouter "implement auth")

[[ "$PROBE" == *$'openrouter/model-a'*$'fail\tprovider error 503'* ]]
[[ "$PROBE" == *$'openrouter/model-b'*$'ok\tlive probe ok'* ]]
[[ "$BEST" == "openrouter/model-b" ]]
[[ "$PLAN" == *"recent live probe failed"* ]]
grep -q $'^openrouter/model-a\t' "$TMP_DIR/health.tsv"
grep -q $'^openrouter/model-b\t' "$TMP_DIR/health.tsv"
