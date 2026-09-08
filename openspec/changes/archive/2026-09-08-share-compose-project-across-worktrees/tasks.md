## 1. Shared router configuration

- [x] 1.1 Add the top-level default project name `d20` without changing the service or network definitions.
- [x] 1.2 Document shared stop/recreate behavior, old router handling, project overrides, and concurrent application limitations in README.

## 2. Verification

- [x] 2.1 Validate Compose configuration from differently named project directories and verify repeated startup reuses the running container while the local module route remains available.
- [x] 2.2 Run strict OpenSpec validation, review the diff, and confirm the existing `just up` command sequence remains unchanged.

Validation on 2026-09-08: `docker compose config --quiet` and JSON resolution passed for `shared-compose-project`, `d20`, and `informative-home-footer` project directories using the updated file without project-name overrides. Alternating native `docker compose up -d` between the implementation worktree and primary checkout three times retained container `c1adaba20fb0`; the existing Koala Rescue Club route returned HTTP 200 after each invocation. Service/network definitions and `justfile` match the baseline exactly. Strict validation passed for all 81 active changes and specifications, and `git diff --check` passed.

After archive, strict validation passed for all 80 remaining items and the change was absent from `openspec list --json`. The repository's `openspec.check.run` Mix task also passed for nine active changes, invoked directly through Elixir with the existing Jason build to avoid initializing unrelated application dependencies in this configuration-only worktree.
