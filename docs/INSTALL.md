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

## Step 5: Verify Installation

```bash
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
