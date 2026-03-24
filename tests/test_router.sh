#!/bin/bash
set -euo pipefail

TODAY="$(date +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

QUICK=$(bash scripts/router.sh classify "fix typo in README")
REASON=$(bash scripts/router.sh classify "explain this auth bug")
TESTING=$(bash scripts/router.sh classify "add pytest coverage")
POLISH_REASON=$(bash scripts/router.sh classify "przyjrzyj kod i powiedz co jest niedokonczone")
POLISH_NOT_JEST=$(bash scripts/router.sh classify "powiedz co jest nie tak i co jeszcze jest niedokonczone")

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
openrouter	openrouter/model-b	openrouter/model-b	free	200000		OPENROUTER_API_KEY
chutes	chutes/devstral-medium	openai/devstral-medium	prepaid	131072	https://llm.chutes.ai/v1	CHUTES_API_KEY
EOF

cat > "$TMP_DIR/fixture.json" <<'EOF'
{"data":[{"id":"coder-free","context_window":64000}]}
EOF

cat > "$TMP_DIR/usage.jsonl" <<EOF
{"date":"$TODAY","provider":"openrouter","model":"openrouter/model-a","task_type":"code","success":false,"ts":1}
{"date":"$TODAY","provider":"openrouter","model":"openrouter/model-a","task_type":"code","success":false,"ts":2}
{"date":"$TODAY","provider":"openrouter","model":"openrouter/model-b","task_type":"code","success":true,"ts":3}
EOF

ROUTER_ENV=(
    CASCADE_HOME="$TMP_DIR"
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl"
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl"
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv"
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false
    CASCADE_MODEL_HEALTH_ENABLED=false
    CASCADE_CLOUD_FREE_ONLY=false
    OPENROUTER_API_KEY=test
    CHUTES_API_KEY=test
    OLLAMA_HOST=http://127.0.0.1:9
)

NO_PROVIDER=$(GROQ_API_KEY= OPENROUTER_API_KEY= GEMINI_API_KEY= GOOGLE_AI_KEY= XAI_API_KEY= CEREBRAS_API_KEY= CHUTES_API_KEY= CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false CASCADE_MODEL_HEALTH_ENABLED=false OLLAMA_HOST=http://127.0.0.1:9 bash scripts/router.sh best "fix typo in README" || true)
STATIC_CLOUD_FALLBACK=$(env CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/missing.tsv" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false CASCADE_MODEL_HEALTH_ENABLED=false OPENROUTER_API_KEY=test GROQ_API_KEY=test GEMINI_API_KEY=test CEREBRAS_API_KEY=test XAI_API_KEY=test OLLAMA_HOST=http://127.0.0.1:9 bash scripts/router.sh best "implement auth")
BEST_OPENROUTER=$(env "${ROUTER_ENV[@]}" bash scripts/router.sh best --provider openrouter "implement auth" || true)
BEST_CHUTES=$(env "${ROUTER_ENV[@]}" bash scripts/router.sh best --provider chutes "implement auth")
MISSING_EXACT=$(env "${ROUTER_ENV[@]}" bash scripts/router.sh best --model openrouter/model-a "implement auth" || true)
PLAN=$(env "${ROUTER_ENV[@]}" bash scripts/router.sh plan "implement auth")
RESOLVE=$(env "${ROUTER_ENV[@]}" bash scripts/router.sh resolve --provider chutes "implement auth")
env CASCADE_MODEL_PROVIDERS=fixture FIXTURE_API_KEY=test CASCADE_PROVIDER_FIXTURE_BASE_URL="https://api.fixture.test/v1" CASCADE_PROVIDER_FIXTURE_MODELS_URL="file://$TMP_DIR/fixture.json" CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/refreshed.tsv" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false CASCADE_MODEL_HEALTH_ENABLED=false bash scripts/router.sh refresh

[[ "$QUICK" == "quick" ]]
[[ "$REASON" == "reason" ]]
[[ "$TESTING" == "test" ]]
[[ "$POLISH_REASON" == "reason" ]]
[[ "$POLISH_NOT_JEST" == "reason" ]]
[[ "$NO_PROVIDER" == "LIMIT_EXCEEDED" ]]
[[ "$STATIC_CLOUD_FALLBACK" == "groq/llama-3.3-70b-versatile" ]]
[[ "$BEST_OPENROUTER" == "openrouter/model-b" ]]
[[ "$BEST_CHUTES" == "chutes/devstral-medium" ]]
[[ "$MISSING_EXACT" == "UNAVAILABLE_MODEL" ]]
[[ "$PLAN" == *"openrouter/model-a"* ]]
[[ "$PLAN" == *"cooldown after recent failures"* ]]
[[ "$RESOLVE" == *"aider_model=openai/devstral-medium"* ]]
[[ "$RESOLVE" == *"api_base=https://llm.chutes.ai/v1"* ]]
grep -q $'^fixture\tfixture/coder-free\topenai/coder-free\tprepaid\t64000\thttps://api.fixture.test/v1\tFIXTURE_API_KEY$' "$TMP_DIR/refreshed.tsv"
