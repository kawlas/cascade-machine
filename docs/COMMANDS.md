# CASCADE MACHINE — Commands

## Coding Commands

| Command | Description | Requires | Mode |
|---------|-------------|----------|------|
| `quick` | Local fast fixes with `qwen3:4b` | Ollama | Local |
| `fast` | Main coding alias with `qwen3-coder` | Ollama | Local |
| `think` | Debug and reasoning with `deepseek-r1:8b` | Ollama | Local |
| `cloud` | Fast cloud coding via Groq | API key + internet | Cloud |
| `smart` | More capable cloud coding via OpenRouter Devstral-2 | API key + internet | Cloud |
| `turbo` | Cloud coding via Cerebras | API key + internet | Cloud |
| `gem` | Cloud coding via Gemini | API key + internet | Cloud |
| `grok` | Cloud coding via x.ai | API key + internet | Cloud |
| `heal "task"` | Self-healing flow with retries, lint, tests, fallback | Ollama or cloud | Hybrid |

### Examples

```bash
quick "fix typo in README"
fast "add validation to user creation"
think "why does this test fail?"
cloud "refactor auth middleware"
smart "implement a multi-file feature safely"
heal "fix the failing build and keep tests green"
```

## CASCADE Tool Commands

| Command | Description |
|---------|-------------|
| `cascade help` | Show the main help screen |
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
cascade doctor
cascade status
cascade config
cascade logs
tokens
```

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
# 1. Check system state
cascade doctor

# 2. Start local work
fast "implement feature X"

# 3. Switch to reasoning when needed
think "explain this bug"

# 4. Use self-healing for tougher tasks
heal "fix tests and keep lint clean"

# 5. Review usage and learnings
cascade status
cascade logs
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
