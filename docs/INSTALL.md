# CASCADE Machine — Installation Guide

## Prerequisites

Before installing CASCADE Machine, ensure you have:

- **macOS** or **Linux** (tested on macOS Sonoma, Ubuntu 22.04)
- **Bash** 5.0+ or **Zsh**
- **Git** installed
- **Homebrew** (macOS only)

## Step 1: Install Dependencies

### Install Ollama (required for local models)

```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh
```

### Install Aider (AI pair programming tool)

```bash
pip3 install aider-chat
```

### Install Python (if not already installed)

```bash
# macOS
brew install python@3.11

# Linux
sudo apt install python3 python3-pip
```

## Step 2: Clone CASCADE Machine

```bash
# Clone the repository
git clone https://github.com/kawlas/cascade-machine.git
cd cascade-machine
```

## Step 3: Run Installation Script

```bash
# Make installer executable
chmod +x install.sh

# Run installer
./install.sh
```

The installer will:
- Create `~/.cascade/` directory
- Copy all scripts to `~/.cascade/`
- Set up shell aliases in `~/.zshrc` or `~/.bashrc`
- Create `~/.cascade/.env` for API keys

## Step 4: Configure API Keys

Edit the environment file:

```bash
nano ~/.cascade/.env
```

Add your API keys (all optional, CASCADE works without them using local Ollama):

```bash
# OpenRouter (29 free models, ~200 req/day)
export OPENROUTER_API_KEY="sk-or-..."

# Groq (fastest cloud, ~800 req/day)
export GROQ_API_KEY="gsk_..."

# Google Gemini (~1500 req/day)
export GEMINI_API_KEY="..."
```

Reload your shell:

```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Step 4a: Manage Providers Over Time

The router is designed so you can change providers without editing the code.

### Add a built-in provider

Add the key to `~/.cascade/.env` and make sure the provider name is present in:

```bash
export CASCADE_MODEL_PROVIDERS="openrouter,groq,gemini,cerebras,xai"
```

### Add a custom provider

For any OpenAI-compatible provider, add:

```bash
export CASCADE_MODEL_PROVIDERS="openrouter,groq,myprovider"
export MYPROVIDER_API_KEY="..."
export CASCADE_PROVIDER_MYPROVIDER_BASE_URL="https://api.example.com/v1"
export CASCADE_PROVIDER_MYPROVIDER_TIER="prepaid"
```

Optional overrides:

```bash
export CASCADE_PROVIDER_MYPROVIDER_MODELS_URL="https://api.example.com/v1/models"
export CASCADE_PROVIDER_MYPROVIDER_LIMIT="200"
export CASCADE_PROVIDER_MYPROVIDER_HEALTHCHECK="true"
export CASCADE_PROVIDER_MYPROVIDER_ENABLED="true"
```

### Disable a provider temporarily

```bash
export CASCADE_PROVIDER_GROQ_ENABLED="false"
```

### Remove a provider completely

1. Remove its name from `CASCADE_MODEL_PROVIDERS`
2. Delete its API key line
3. Delete its `CASCADE_PROVIDER_<NAME>_*` lines

### Update limits or pricing tier

If a provider changes its free tier, prepaid credits, or pricing, update:

```bash
export CASCADE_PROVIDER_OPENROUTER_TIER="paid"
export CASCADE_PROVIDER_OPENROUTER_LIMIT="50"
```

Supported tiers used by the ranking:

- `free`
- `prepaid`
- `paid`
- `local`

### Refresh the live model list

```bash
bash ~/.cascade/router.sh refresh
bash ~/.cascade/router.sh providers
bash ~/.cascade/router.sh probe "test task"
```

### Provider Maintenance Checklist

Run this whenever a provider changes pricing, limits, or availability:

1. Update `~/.cascade/.env`:
`CASCADE_MODEL_PROVIDERS`, `<NAME>_API_KEY`, `CASCADE_PROVIDER_<NAME>_BASE_URL`,
`CASCADE_PROVIDER_<NAME>_MODELS_URL`, `CASCADE_PROVIDER_<NAME>_TIER`,
`CASCADE_PROVIDER_<NAME>_LIMIT`, `CASCADE_PROVIDER_<NAME>_ENABLED`.
2. `bash ~/.cascade/router.sh refresh`
3. `bash ~/.cascade/router.sh providers`
4. `bash ~/.cascade/router.sh probe "test task"`
5. `bash ~/.cascade/router.sh plan "test task"`

## Step 5: Verify Installation

```bash
# Load current runtime config into this shell
cascade start

# Run diagnostics
cascade doctor

# Check status
cascade status

# Test local model
fast "write hello world in python"
```

## Step 6: Download Ollama Models

```bash
# Recommended models
ollama pull qwen3-coder      # best for coding (18GB)
ollama pull devstral         # best for planning (14GB)
ollama pull deepseek-r1:8b   # reasoning/debug (5GB)
ollama pull qwen3:4b         # fast simple tasks (2.5GB)

# Verify models
ollama list
```

## Post-Installation

### Daily use after opening a new terminal

```bash
cascade start
cascade
```

`cascade` opens the interactive chat on the best available cloud coding model. If cloud is unavailable, CASCADE falls back to local Ollama automatically.
If `fast` works locally, `cascade` and `cascade "task"` should also be able to reuse that local Ollama setup.

`cascade start` reloads `~/.cascade/.env` and the current aliases in your shell, so you keep using the latest installed runtime without remembering extra setup steps.

If you want the welcome screen with command hints, run `cascade dashboard`.

After that, you usually work with the short aliases you already know:

```bash
fast "add user authentication"
think "why does this test fail?"
quick "fix typo in README"
smart "refactor auth flow"
```

Important:

- `cascade "task"` opens the app chat and keeps your task visible when the chat starts.
- `quick`, `think`, and `cloud` open chat sessions with different routing bias.
- `fast`, `smart`, `gem`, `grok`, and `turbo` are direct shortcuts to specific models.
- If one cloud provider hits limits during `cloud`, CASCADE can move to another candidate instead of staying on one fixed model.

Use automatic mode only when you want CASCADE to take over retries, tests, linting, and model switching:

```bash
cascade run "fix the failing build"
heal "fix the failing build"
cascade think "debug flaky login test"
cascade quick "repair small regression"
```

### Update runtime after changing this repository

```bash
cascade sync
```

This reruns the installer from the repo that last installed `~/.cascade`, so you do not need to remember `./install.sh` every time you change the source code.

You do not need `cascade sync` for normal coding in your own project. Use it only when you changed CASCADE itself in this repository and want to refresh the installed runtime.

### Initialize Your First Project

```bash
cd my-project/
cascade-init
fast "add user authentication"
```

### Setup Nightly Analysis (optional)

```bash
# Add cron job for daily analysis at 23:00
(crontab -l 2>/dev/null; echo "0 23 * * * ~/.cascade/nightly.sh >> ~/.cascade/logs/nightly.log 2>&1") | crontab -
```

## Troubleshooting

### Ollama not running

```bash
ollama serve &
sleep 3
ollama list
```

### Aliases not working

```bash
# Reload shell config
source ~/.zshrc

# Or manually load aliases
bash ~/.cascade/aliases.sh --load
```

### Permission denied errors

```bash
chmod +x ~/.cascade/*.sh
```

### Reset installation

```bash
# Remove and reinstall
rm -rf ~/.cascade
./install.sh --force
```

## Next Steps

- Read [../README.md](../README.md) for usage guide
- Read [COMMANDS.md](COMMANDS.md) for all available commands
- Read [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
