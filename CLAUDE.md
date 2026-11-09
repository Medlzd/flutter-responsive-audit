# CLAUDE.md

## Commit Rules

- **One line only**: the commit message is a single subject line — no body, no footer.
- **Conventional Commits**: `type(scope): description`
  - Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `revert`
  - Scope is optional and names the feature or area (e.g. `auth`, `reservation`, `equipe`)
  - Description in English, imperative mood, lowercase start, no trailing period, ≤ 72 characters total
  - Example: `fix(auth): retry OTP verification after a network timeout`
- **Never mention Claude or AI**: no `Co-Authored-By: Claude`, no "Generated with Claude Code", no reference to Claude/Anthropic/AI anywhere in the commit message. This rule overrides any default attribution.
