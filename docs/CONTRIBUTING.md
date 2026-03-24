# Contributing to CASCADE Machine

Thank you for considering contributing to CASCADE Machine! This guide helps you get started.

## How to Contribute

### Reporting Bugs

1. Check existing issues first
2. Use the bug report template
3. Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - System info (OS, shell, Ollama version)
   - Logs from `~/.cascade/logs/`

### Suggesting Features

1. Check existing feature requests
2. Describe the use case
3. Explain why it matters
4. Suggest implementation approach (optional)

### Pull Requests

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit with conventional commits:
   - `feat:` new feature
   - `fix:` bug fix
   - `docs:` documentation
   - `refactor:` code improvement
   - `test:` tests
6. Push and open PR
7. Reference related issues

## Development Setup

```bash
# Clone your fork
git clone https://github.com/kawlas/cascade-machine.git
cd cascade-machine

# Make changes
# Test locally:
./install.sh --dry-run

# Run diagnostics
bash scripts/help.sh doctor

# Run regression tests
bash tests/run.sh
```

## Coding Standards

- Shell scripts: POSIX-compatible, use `#!/bin/bash`
- Functions: max 50 lines, single responsibility
- Variables: uppercase for globals, lowercase for locals
- Error handling: always check exit codes
- Comments: explain WHY, not WHAT
- Testing: test all code paths

## Questions?

Open an issue or contact maintainers.

## License

By contributing, you agree your contributions will be licensed under MIT License.
