# Architecture Decisions

Format: Date | Decision | Reason | Source (Cloud Model)

2026-03-24 | Repository root is the source of truth for CASCADE Machine, and `~/.cascade` is runtime-only | Prevent drift between documented code and installed user copy | Codex
2026-03-24 | `cascade "task"` is the default human entrypoint, while `heal` remains the underlying compatibility engine | Keep self-healing behavior as the product default without breaking existing scripts | Codex
