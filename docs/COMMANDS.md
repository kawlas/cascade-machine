# CASCADE MACHINE — Commands

## Mental Model

Use CASCADE in four layers:

1. `cascade`
   Open the interactive chat on the best available cloud model, with local Ollama fallback.
2. `cascade dashboard`
   Show the welcome dashboard with current status and the most important commands.
3. `cascade start`
   Run once after opening a new terminal. It loads `~/.cascade/.env` and aliases into the current shell.
4. Direct model shortcuts
   Use `fast`, `smart`, `gem`, `grok`, or `turbo` when you want a specific fixed model shortcut.
5. Automatic self-healing
   Use `cascade run "task"` or `heal "task"` when you want CASCADE to pick models, retry, lint, test, and recover automatically.
6. Runtime maintenance
   Use `cascade sync` only after changing CASCADE itself in this repository.

Slash-style shortcuts are also supported inside CASCADE itself, for example `cascade /doctor`, `cascade /models`, and `cascade /sync`.

## Coding Commands

| Command | Description | Requires | Mode |
|---------|-------------|----------|------|
| `cascade` | Open interactive chat on the best cloud coding model, with local fallback | Ollama or cloud | Hybrid |
| `cascade "task"` | Open app chat with your task shown in the launcher | Ollama or cloud | Hybrid |
| `cascade run "task"` | Unattended self-healing task runner with retries, lint, tests, fallback | Ollama or cloud | Hybrid |
| `quick` | Open lightweight chat with optional starting task | Ollama or cloud | Hybrid |
| `fast` | Main coding alias with `qwen3-coder` | Ollama | Local |
| `think` | Open reasoning chat with optional starting task | Ollama or cloud | Hybrid |
| `cloud` | Open cloud-first chat with optional starting task | Ollama or cloud | Hybrid |
| `smart` | More capable cloud coding via OpenRouter Devstral-2 | API key + internet | Cloud |
| `turbo` | Cloud coding via Cerebras | API key + internet | Cloud |
| `gem` | Cloud coding via Gemini | API key + internet | Cloud |
| `grok` | Cloud coding via x.ai | API key + internet | Cloud |
| `heal "task"` | Compatibility alias for the self-healing engine | Ollama or cloud | Hybrid |

### Examples

```bash
cascade
quick "fix typo in README"
think "why does this test fail?"
cloud "refactor auth middleware"

# direct fixed-model shortcuts
fast "add validation to user creation"
smart "implement a multi-file feature safely"

# chat-first mode
cascade "fix the failing build and keep tests green"
cascade think "why does this test fail?"
cascade quick "fix typo in README"
cascade cloud "refactor auth middleware"

# unattended automation
cascade run "repair build automatically and keep tests green"
heal "repair build automatically and keep tests green"
```

## CASCADE Tool Commands

| Command | Description |
|---------|-------------|
| `cascade` | Open the interactive CASCADE chat |
| `cascade dashboard` | Show the welcome dashboard with status and key commands |
| `cascade /doctor` | Slash shortcut for `cascade doctor` |
| `cascade /models` | Slash shortcut for `cascade models` |
| `cascade /sync` | Slash shortcut for `cascade sync` |
| `cascade help` | Show the main help screen |
| `cascade start` | Reload `~/.cascade/.env` and aliases in the current shell |
| `cascade sync` | Reinstall runtime from the repo that was last used for install |
| `cascade doctor` | Check installation, Ollama, keys, aliases |
| `cascade status` | Show model and key status |
| `cascade config` | Configure API keys, `AIDER_MODEL`, cron |
| `cascade models` | Show available model categories |
| `cascade keys` | Show API-key setup info |
| `cascade logs` | Show nightly reports and recent learnings |
| `cascade update` | Update Aider and Ollama |
| `tokens` | Shortcut to model usage/status |

### Examples

```bash
cascade
cascade start
cascade sync
cascade doctor
cascade status
cascade config
cascade logs
tokens
```

## Router Commands

These commands help manage dynamic providers and live model availability:

| Command | Description |
|---------|-------------|
| `bash ~/.cascade/router.sh refresh` | Refresh live model catalog from provider APIs |
| `bash ~/.cascade/router.sh providers` | Show configured providers, tier, and discovered model counts |
| `bash ~/.cascade/router.sh best "task"` | Return the best current model for a task |
| `bash ~/.cascade/router.sh plan "task"` | Show ranked candidates and why they were accepted or skipped |
| `bash ~/.cascade/router.sh probe "task"` | Actively probe top candidates and show which ones respond now |
| `bash ~/.cascade/router.sh resolve "task"` | Show resolved model plus runtime details like `api_base` |
| `bash ~/.cascade/router.sh best --provider openrouter "task"` | Restrict selection to one provider |
| `bash ~/.cascade/router.sh best --model openrouter/model-id "task"` | Force a specific model if it is available |

### Provider Config Keys

Provider behavior is controlled from `~/.cascade/.env`:

- `CASCADE_MODEL_PROVIDERS`
- `CASCADE_PROVIDER_<NAME>_BASE_URL`
- `CASCADE_PROVIDER_<NAME>_MODELS_URL`
- `CASCADE_PROVIDER_<NAME>_TIER`
- `CASCADE_PROVIDER_<NAME>_LIMIT`
- `CASCADE_PROVIDER_<NAME>_ENABLED`
- `CASCADE_PROVIDER_<NAME>_HEALTHCHECK`
- `<NAME>_API_KEY`

### Maintenance Flow

Use this when a provider changes pricing, limits, or availability:

1. Update `~/.cascade/.env` for that provider.
2. `bash ~/.cascade/router.sh refresh`
3. `bash ~/.cascade/router.sh providers`
4. `bash ~/.cascade/router.sh probe "test task"`
5. `bash ~/.cascade/router.sh plan "test task"`

## Project Bootstrap

| Command | Description |
|---------|-------------|
| `cascade-init` | Auto-detect project type in current folder |
| `cascade-init folder --react` | Create a React project workspace |
| `cascade-init folder --python` | Create a Python project workspace |
| `cascade-init folder --node` | Create a Node/API project workspace |
| `cascade-init folder --ml` | Create an ML/Data Science workspace |
| `cascade-init folder --go` | Create a Go workspace |
| `cascade-init folder --cli` | Create a CLI-tool workspace |

### Generated Files

`cascade-init` creates:
- `AGENTS.md`
- `.aider.conf.yml`
- `.kilocode`
- `.cascade/decisions.md`
- `.cascade/learnings.md`
- `.cascade/commands.md`

## Recommended Workflow

```bash
# 1. Start a new shell session
cascade start

# 2. Open the chat
cascade

# 3. Optional: check system state
cascade doctor

# 4. Normal day-to-day work
quick "fix typo in docs"
think "explain this bug"
cloud "repair build using cloud only"

# 5. Use fixed-model shortcuts when you know what you want
fast "implement feature X"
smart "refactor auth flow safely"

# 6. Use automatic mode when you want broader self-healing
cascade "fix the failing build"
cascade think "explain this bug"
cascade quick "fix tests and keep lint clean"

# 7. Review usage and learnings
cascade status
cascade logs

# 8. Only after changing CASCADE itself
cascade sync
```

## Key Files

| File | Description |
|------|-------------|
| `~/.cascade/.env` | Runtime API keys and optional `AIDER_MODEL` |
| `~/.cascade/docs/INSTALL.md` | Installed documentation |
| `.aider.conf.yml` | Aider configuration in a project |
| `AGENTS.md` | Instructions for AI agents in a project |
| `.cascade/decisions.md` | Architecture decisions for a project |
| `.cascade/learnings.md` | Project learnings |
| `.cascade/commands.md` | Project-specific developer commands |
