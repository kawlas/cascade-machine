# Hey! You're in the project!

## Universal Rules
- Write clean, readable code with meaningful variable/function names
- Add error handling to ALL I/O operations (network, file, DB)
- Every new function needs at least one test
- Functions: max 30 lines. Files: max 300 lines — split if larger
- Comments explain WHY, not WHAT
- Never hardcode secrets, API keys, or environment-specific config
- Commit messages: conventional commits (feat:, fix:, refactor:, docs:, test:)
- When unsure about architecture → ask, don't assume
- Read .cascade/decisions.md before making architectural changes


## Additional Guidelines
- Follow the existing patterns in the codebase
- When adding new functionality, look for similar implementations first
- Keep changes focused: one feature or fix per commit
- Update documentation when changing public interfaces
- Use automated code reviews with cloud tools to ensure adherence to best practices
- Implement automated test generation for edge cases and error handling
- Maintain up-to-date API documentation using cloud-generated documentation tools
- Integrate performance monitoring to identify bottlenecks proactively
