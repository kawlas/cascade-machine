# Repository Structure

## Goal

This repository is the complete source package for CASCADE Machine. A new user should be able to clone it, read the active docs, run `./install.sh`, and get a working installation in `~/.cascade`.

## Top-Level Layout

- `README.md`
  Main entrypoint for new users.
- `install.sh`
  Installer that copies the packaged application into `~/.cascade`.
- `scripts/`
  Executable source files for the application.
- `docs/`
  Active documentation for users and contributors.
- `.cascade/`
  Templates and project-level support files created or referenced by `cascade-init`.
- `examples/`
  Small demos or sandboxes.
- `.env.cascade`
  Safe template for API keys.
- `AGENTS.md`
  Rules for AI agents working in this repository.

## What Goes Where

### `scripts/`

Application logic that becomes runnable in the installed environment:
- `aliases.sh`
- `help.sh`
- `router.sh`
- `heal.sh`
- `init-project.sh`
- `nightly.sh`

### `docs/`

Active documentation:
- `ARCHITECTURE.md`
- `INSTALL.md`
- `COMMANDS.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `STRUCTURE.md`

### `docs/legacy/`

Historical or exploratory materials kept for reference, not as the source of truth for the shipped product.

### `.cascade/`

Project bootstrap and template support files:
- `commands.md`
- `decisions.md`
- `learnings.md`

### `examples/`

Non-production example projects or test sandboxes.

Historical local workspaces should not live here. If they are worth keeping, move them to `docs/legacy/internal/`.

## Source of Truth Rule

If behavior exists only in `~/.cascade` and not in this repository, it is not truly shipped yet. All product changes should land here first.
