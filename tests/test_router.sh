#!/bin/bash
set -euo pipefail

QUICK=$(bash scripts/router.sh classify "fix typo in README")
REASON=$(bash scripts/router.sh classify "explain this auth bug")
TESTING=$(bash scripts/router.sh classify "add pytest coverage")
NO_PROVIDER=$(GROQ_API_KEY= OPENROUTER_API_KEY= GEMINI_API_KEY= GOOGLE_AI_KEY= XAI_API_KEY= CEREBRAS_API_KEY= OLLAMA_HOST=http://127.0.0.1:9 bash scripts/router.sh best "fix typo in README" || true)

[[ "$QUICK" == "quick" ]]
[[ "$REASON" == "reason" ]]
[[ "$TESTING" == "test" ]]
[[ "$NO_PROVIDER" == "LIMIT_EXCEEDED" ]]
