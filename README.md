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
cascade-init

# 4. Start coding
fast "add user authentication"
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
heal "add email validation to POST /users"
heal --reason "debug memory leak in auth module"
heal --fast "fix typo in README"
```

Automatically escalates through models until the task succeeds.

### Smart Model Routing

- Local: Ollama models, offline and unlimited
- Cloud: Groq, Cerebras, Google, OpenRouter, x.ai free tiers
- Model choice based on task type, availability, and past success

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
| `fast` | Aider + Ollama qwen3-coder | $0 unlimited |
| `think` | Aider + DeepSeek-R1 8B | $0 unlimited |
| `quick` | Aider + Ollama qwen3:4b | $0 unlimited |
| `cloud` | Aider + Groq llama-70b | $0 limited |
| `heal "task"` | Auto-escalating self-healing | mixed |
| `tokens` | Check daily usage status | - |
| `cascade-init` | Setup a project for AI work | - |
| `cascade doctor` | System diagnostics | - |

More commands: [docs/COMMANDS.md](docs/COMMANDS.md)

## New Project Setup

```bash
cd new-project/
cascade-init
fast "add user authentication"
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
