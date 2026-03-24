# CASCADE Machine Architecture

## Purpose

CASCADE Machine is a personal AI development framework that wraps local and cloud models into one repeatable coding workflow. The repository is the source of truth for installation, while `~/.cascade` is the deployed runtime on a user's machine.

## System Layout

### 1. Source Distribution Layer
- Repository root contains the installable package.
- Key files:
  - `install.sh` installs the framework into `~/.cascade`.
  - `scripts/` contains executable source files copied during installation.
  - `scripts/lib/` contains shared shell modules used by those entrypoints.
  - `docs/` contains active user and contributor documentation.
  - `.env.cascade` is the safe template for secrets configuration.

This layer should be complete enough that another user can clone the repo and run `./install.sh`.

### 2. Runtime Layer
- Installation target: `~/.cascade`
- This is the user's local operational environment.
- It contains:
  - executable scripts,
  - optional API-key file `.env`,
  - usage history in `usage.jsonl`,
  - execution learnings in `learnings.jsonl`,
  - logs in `logs/`.

The runtime is mutable and user-specific. It should never be treated as the canonical source for code changes.

### 3. Command Layer
- `scripts/aliases.sh` exposes user-facing shell commands.
- `scripts/lib/` supports the command layer with reusable runtime logic.
- Main entrypoints:
  - `cascade`
  - `heal`
  - `cascade-init`
  - `tokens`

This layer makes the framework feel like a native CLI instead of a set of loose shell scripts.

### 4. Routing Layer
- `scripts/router.sh` decides which model should handle a task.
- Inputs:
  - task text,
  - task classification,
  - dynamic provider model catalog,
  - provider health probes,
  - provider daily usage,
  - historical success data.
- Outputs:
  - best model choice,
  - status information for the user.

Its job is cost-aware orchestration: prefer the best currently-available free or prepaid cloud option, then fall back to lightweight local Ollama only when needed.

### 5. Execution and Recovery Layer
- `scripts/heal.sh` is the unattended automation engine behind `heal "task"` and `cascade run "task"`.
- Responsibilities:
  - classify work,
  - select a model tier,
  - call `aider`,
  - run lint and tests,
  - rollback to git baseline between attempts,
  - store success and failure learnings.

This is the self-healing core of the system.

### 6. Project Bootstrap Layer
- `scripts/init-project.sh` initializes a working repo for AI-assisted development.
- It creates project-local standards such as:
  - `AGENTS.md`
  - `.aider.conf.yml`
  - `.kilocode`
  - `.cascade/decisions.md`
  - `.cascade/learnings.md`
  - `.cascade/commands.md`

This layer standardizes how new projects should collaborate with AI agents.

### 7. Feedback and Improvement Layer
- `scripts/nightly.sh` analyzes learnings and usage data.
- It produces:
  - success metrics,
  - provider usage summaries,
  - recommendations,
  - suggestions for improving project instructions.

This layer closes the loop so the framework can improve model choice and working rules over time.

## Primary Flow

1. User clones the repository.
2. User runs `./install.sh`.
3. Installer copies the packaged files into `~/.cascade` and wires shell aliases.
4. In a project directory, user runs `cascade-init`.
5. User works through commands like `cascade`, `cascade "task"`, `cascade run "task"`, `fast`, `think`, or `cascade doctor`.
6. Runtime data accumulates in `~/.cascade`.
7. `nightly.sh` analyzes that data and recommends improvements.

## Source of Truth Rules

- The repository should contain all installable code, templates, and documentation.
- `~/.cascade` should contain only deployed runtime artifacts and user-specific state.
- New features should be implemented in the repository first, then installed into `~/.cascade`.
- Documentation in the repo must describe the packaged behavior, not a hand-tuned local machine.

## Recommended Repository Shape

- Keep `install.sh` in the repository root as the main installation entrypoint.
- Keep executable runtime sources in `scripts/`.
- Keep active docs in `docs/`.
- Keep project templates in `.cascade/`.
- Keep runtime-only files out of git:
  - `.env`
  - logs
  - usage history
  - local caches
  - experimental sandboxes

## Why This Matters

Without this split, the project drifts into two versions:
- the documented version in git,
- the actually working version in `~/.cascade`.

The fix is simple: the repo must become the product, and `~/.cascade` must become only the installed copy.
