## 1. Restore Development Startup

- [x] 1.1 Restore `serve` as a direct `phx.server` alias while preserving `start` delegation.
- [x] 1.2 Run `mix setup` once before `just serve` starts the existing configuration watcher.
- [x] 1.3 Update startup documentation to describe one-time setup, server-only watched replacements, and deliberate migration application.

## 2. Validate the Workflow

- [x] 2.1 Validate Mix and Just formatting plus dry-run rendering for default and overridden `serve` arguments.
- [x] 2.2 Verify a fresh watched child starts Bandit and serves an HTTP response on the configured development port.
- [x] 2.3 Run strict validation for this change and the complete OpenSpec tree, then review the diff without including unrelated worktree changes.
