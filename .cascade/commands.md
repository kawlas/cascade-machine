# CASCADE — Wszystkie komendy

## Kodowanie

| Komenda | Opis | Wymagania |
|---------|------|-----------|
| `quick` | devstral-small do małych, szybkich poprawek | Ollama |
| `fast` | qwen3-coder do normalnej pracy nad kodem | Ollama |
| `think` | deepseek-r1:14b do debugowania i wyjaśnień | Ollama |
| `cloud` | Groq llama-70b do szybkiego cloud coding | Klucz API + internet |
| `smart` | OpenRouter Devstral-2 do trudniejszych zmian | Klucz API + internet |
| `turbo` | Cerebras llama-70b jako szybki fallback | Klucz API + internet |
| `gem` | Gemini 2.0 Flash | Klucz API + internet |
| `grok` | x.ai Grok mini | Klucz API + internet |
| `heal "zadanie"` | Self-healing flow z retry, lintem i testami | Ollama lub cloud |

## Narzędzia CASCADE

| Komenda | Opis |
|---------|------|
| `cascade help` | Pokaż ekran pomocy |
| `cascade doctor` | Sprawdź instalację, modele, klucze i aliasy |
| `cascade status` | Pokaż status modeli i kluczy |
| `cascade config` | Skonfiguruj klucze, `AIDER_MODEL` i cron |
| `cascade models` | Lista modeli i kategorii użycia |
| `cascade keys` | Informacje o kluczach API |
| `cascade logs` | Pokaż raporty nocne i ostatnie learnings |
| `cascade update` | Aktualizacja Aider i Ollama |
| `tokens` | Skrót do zużycia providerów w routerze |

## Nowy projekt

| Komenda | Opis |
|---------|------|
| `cascade-init` | Auto-detect typu projektu w bieżącym katalogu |
| `cascade-init folder --react` | Nowy projekt React |
| `cascade-init folder --python` | Nowy projekt Python |
| `cascade-init folder --node` | Nowy projekt Node/API |
| `cascade-init folder --ml` | Nowy projekt ML/Data Science |
| `cascade-init folder --go` | Nowy projekt Go |
| `cascade-init folder --cli` | Nowy projekt CLI |

## Szybkie wskazówki

- Zacznij zwykle od `fast`.
- Używaj `think`, gdy potrzebujesz diagnozy albo wyjaśnienia.
- Używaj `heal`, gdy chcesz połączyć retry, lint i testy.
- Jeśli nie masz internetu, `quick`, `fast` i `think` działają lokalnie.
- Klucze trzymamy w `~/.cascade/.env`.
