# CASCADE Machine

> **AI-Powered Coding Framework** — Code smarter with local + cloud AI models, self-healing workflows, and intelligent task routing.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-5.0+-blue.svg)](https://www.gnu.org/bash/)
[![Ollama](https://img.shields.io/badge/Ollama-Compatible-orange.svg)](https://ollama.ai)
[![Aider](https://img.shields.io/badge/Aider-Compatible-green.svg)](https://aider.chat)

## Quick Start

```bash
# 1. Install (one-time setup)
git clone https://github.com/kawlas/cascade-machine.git
cd cascade-machine
./install.sh

# 2. Configure API keys (optional, works without)
nano ~/.cascade/.env

# 3. In any project directory
cd my-project
cascade start
cascade-init

# 4. Start coding
fast "add user authentication"
```

After you change the source repo later, run `cascade sync` to refresh the installed runtime in `~/.cascade`.

## How To Use It Day To Day

Think about CASCADE in four simple buckets:

- `cascade` without arguments opens the chat on the best available cloud coding model, with local Ollama fallback.
- `cascade dashboard` shows the welcome dashboard with status and basic commands.
- `cascade start` is session setup. Run it once after opening a new terminal.
- `fast`, `quick`, `think`, `smart`, `cloud`, `gem`, `grok`, `turbo` are your direct shortcuts to specific models. This is the old workflow and it still works.
- `cascade "task"` opens the app chat and keeps your task visible in the launcher before chat starts.
- `cascade run "task"` is the unattended automatic mode. Use it when you want the system to retry, test, lint, and switch models for you.
- `cascade sync` is maintenance. Use it only after changing CASCADE itself in this repository.

For convenience, slash-style commands also work inside CASCADE itself, for example `cascade /doctor`, `cascade /models`, or `cascade /sync`.

Typical session:

```bash
cascade start
cascade
fast "add user authentication"
think "why does this test fail?"
quick "fix typo in README"
smart "refactor auth flow safely"
```

In this workflow:

- `quick`, `think`, and `cloud` open chat sessions with different routing bias.
- `fast`, `smart`, `gem`, `grok`, and `turbo` stay direct shortcuts to specific models.
- If `cloud` hits one provider limit, the chat launcher can move to another cloud candidate instead of staying stuck on one model.

Automatic session:

```bash
cascade start
cascade "fix the failing build"
cascade think "debug flaky login test"
cascade quick "repair small regression in README"
cascade run "repair build automatically and keep tests green"
```

## What This Repo Contains

This repository is the source package for CASCADE Machine.

- `install.sh` is the only root entrypoint needed for installation.
- `scripts/` contains the executable source files shipped to `~/.cascade`.
- `docs/` contains active documentation for installation, usage, and architecture.
- `.cascade/` contains project templates and supporting documents.
- `examples/` contains small sample or sandbox projects.
- `~/.cascade` is only the installed runtime created by `./install.sh`.

Architecture overview: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
Repository layout: [docs/STRUCTURE.md](docs/STRUCTURE.md)

## Features

### Self-Healing Coding

```bash
cascade "add email validation to POST /users"
cascade think "debug memory leak in auth module"
cascade quick "fix typo in README"
```

Interactive app chat is now the default entrypoint. `heal` still exists as a compatibility/advanced command, and `cascade run "task"` keeps the unattended self-healing workflow.

If you prefer direct model shortcuts, keep using `fast`, `smart`, `gem`, `grok`, and `turbo`. `cascade "task"` opens the app chat, while `cascade run "task"` runs the unattended automation. `quick` / `think` / `cloud` also open chat sessions.

You do not need to choose `quick`, `think`, or `cloud` every time. Plain `cascade "task"` opens the normal app flow, and `cascade run "task"` classifies the task automatically for unattended execution.
If you just want to open the chat immediately, run `cascade` or `cloud`.

### Smart Model Routing

- Dynamic model catalog refreshed from provider APIs
- Cloud-first routing across Groq, Cerebras, Google, OpenRouter, x.ai, plus custom OpenAI-compatible providers
- Lightweight Ollama fallback only when cloud is exhausted or unavailable
- Active health checks probe top candidates before selection and cache the result
- Ranking based on task type, free/prepaid/local tier, provider limits, recent failures, and past success
- Manual override via `router.sh plan`, `router.sh probe`, `router.sh resolve`, `--provider`, and `--model`

### Provider Management

Providers are no longer hardcoded into the router logic. In practice this means:

- add a provider by adding it to `CASCADE_MODEL_PROVIDERS` and setting its env vars,
- disable a provider by setting `CASCADE_PROVIDER_<NAME>_ENABLED=false`,
- remove a provider by deleting it from `CASCADE_MODEL_PROVIDERS`,
- update limits or tier by editing `CASCADE_PROVIDER_<NAME>_LIMIT` and `CASCADE_PROVIDER_<NAME>_TIER`,
- refresh the live model catalog with `router.sh refresh`.

Built-in providers work out of the box:

- `openrouter`
- `groq`
- `gemini`
- `cerebras`
- `xai`

### Model selection guidance (lighter vs capable)

- The router ranks candidates by tier, health, cooldowns, historical success, and task affinity, but you still decide whether to skew toward lighter or more capable models. Use `bash ~/.cascade/router.sh plan "task"` to see how the scheduler scores providers so you can override with `--provider` or `--model` when needed.
- For lighter runs, use `quick` (local `qwen3:4b`) or `gem` (cloud `gemini-2.0-flash`). To force a cloud lightweight model: `bash ~/.cascade/router.sh best --model gemini/gemini-2.0-flash "task"`.
- For OpenRouter, run `bash ~/.cascade/router.sh plan --provider openrouter "task"` and pick a model with names like `flash`, `mini`, or `small`, then pin it with `--model openrouter/<model-id>`.
- Local Ollama fallbacks such as `qwen3-coder`, `qwen3:4b`, and `devstral-small` stay in the mix as final resorts; the router also inspects installed Ollama models so a working local setup remains usable even when the static fallback list is stale.
- To bias the router per task type, set overrides in `~/.cascade/.env` (task types include `quick`, `test`, `reason`, `code`, and `refactor`).

```bash
export CASCADE_QUICK_MODELS="ollama_chat/qwen3:4b,gemini/gemini-2.0-flash"
export CASCADE_TEST_MODELS="ollama_chat/qwen3:4b,openrouter/mistralai/devstral-2"
export CASCADE_REASON_MODELS="ollama_chat/deepseek-r1:8b,gemini/gemini-2.0-flash"
export CASCADE_CODE_MODELS="ollama_chat/qwen3-coder,openrouter/mistralai/devstral-2"
export CASCADE_REFACTOR_MODELS="openrouter/mistralai/devstral-2,gemini/gemini-2.0-flash"
```

### Evaluating new providers (NVIDIA Nemotron / "Neutron?")

- I did not find a built-in NVIDIA provider in this repo. If you meant NVIDIA **Nemotron** (not “Neutron”), NVIDIA NIM docs describe OpenAI-style endpoints such as `/v1/chat/completions` and `/v1/models`, so it should be wireable as a custom provider if you have a NIM endpoint and API key. citeturn1search12
- If Nemotron is only exposed through OpenRouter, keep it behind the `openrouter` entry and let the catalog refresh pull in its models. If you can call NVIDIA's endpoint directly, add a provider token (e.g., `nim`) to `CASCADE_MODEL_PROVIDERS`, set `NIM_API_KEY`, `CASCADE_PROVIDER_NIM_BASE_URL`, and `CASCADE_PROVIDER_NIM_MODELS_URL`, then run `bash ~/.cascade/router.sh refresh` followed by `probe`/`plan` to confirm it responds.
- Record the decision in `.cascade/decisions.md` so we remember whether Nemotron is routed directly or via an intermediary, and update `CASCADE_MODEL_PROVIDERS` in `.env` when the picture changes.

Custom providers are supported when they expose an OpenAI-compatible inference API. Example:

```bash
export CASCADE_MODEL_PROVIDERS="openrouter,groq,gemini,cerebras,xai,chutes"
export CHUTES_API_KEY="..."
export CASCADE_PROVIDER_CHUTES_BASE_URL="https://llm.chutes.ai/v1"
export CASCADE_PROVIDER_CHUTES_TIER="prepaid"
```

If a provider changes pricing or stops offering a free tier, you usually only need to update env:

```bash
export CASCADE_PROVIDER_OPENROUTER_TIER="paid"
export CASCADE_PROVIDER_OPENROUTER_LIMIT="50"
```

If a provider changes its API base or models endpoint, update:

```bash
export CASCADE_PROVIDER_<NAME>_BASE_URL="https://api.example.com/v1"
export CASCADE_PROVIDER_<NAME>_MODELS_URL="https://api.example.com/v1/models"
```

### Provider Maintenance Checklist

Use this when providers, pricing, or free tiers change:

1. Edit `~/.cascade/.env` and update:
`CASCADE_MODEL_PROVIDERS`, `<NAME>_API_KEY`, `CASCADE_PROVIDER_<NAME>_BASE_URL`,
`CASCADE_PROVIDER_<NAME>_MODELS_URL`, `CASCADE_PROVIDER_<NAME>_TIER`,
`CASCADE_PROVIDER_<NAME>_LIMIT`, `CASCADE_PROVIDER_<NAME>_ENABLED`.
2. Refresh the model catalog: `bash ~/.cascade/router.sh refresh`
3. Verify provider list: `bash ~/.cascade/router.sh providers`
4. Probe live availability: `bash ~/.cascade/router.sh probe "test task"`
5. Check ranking behavior: `bash ~/.cascade/router.sh plan "test task"`

### Nightly Analysis

Runs at 23:00 daily and provides:
- success-rate metrics,
- provider usage summaries,
- actionable recommendations,
- AGENTS.md improvement suggestions.

### Project Templates

```bash
cascade-init my-app --react
cascade-init my-app --python
cascade-init my-app --node
cascade-init my-app --ml
cascade-init my-app --go
cascade-init my-app --cli
```

## Core Commands

| Command | Description | Cost |
|---------|-------------|------|
| `cascade` | Open chat on best cloud model, fallback to local Ollama | mixed |
| `cascade "task"` | Open app chat with your task visible in the launcher | mixed |
| `cascade run "task"` | Unattended self-healing task runner | mixed |
| `fast` | Aider + Ollama qwen3-coder | $0 unlimited |
| `think` | Reasoning chat or self-healing shortcut | mixed |
| `quick` | Lightweight chat or self-healing shortcut | mixed |
| `cloud` | Cloud-first chat or self-healing shortcut with local fallback | mixed |
| `tokens` | Check daily usage status | - |
| `cascade-init` | Setup a project for AI work | - |
| `cascade doctor` | System diagnostics | - |

More commands: [docs/COMMANDS.md](docs/COMMANDS.md)

## New Project Setup

```bash
cd new-project/
cascade-init
cascade "add user authentication"
```

Files created per project:
- `AGENTS.md`
- `.aider.conf.yml`
- `.kilocode`
- `.cascade/decisions.md`
- `.cascade/learnings.md`
- `.cascade/commands.md`

## Documentation

- [docs/INSTALL.md](docs/INSTALL.md)
- [docs/COMMANDS.md](docs/COMMANDS.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/STRUCTURE.md](docs/STRUCTURE.md)
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
- [docs/CHANGELOG.md](docs/CHANGELOG.md)
- [docs/legacy/README.md](docs/legacy/README.md)

## Packaging Rule

If a feature exists only in `~/.cascade` and not in this repository, it is not fully shipped yet.
