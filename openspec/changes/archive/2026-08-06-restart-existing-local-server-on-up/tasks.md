## 1. Development Workflow

- [x] 1.1 Replace process termination in `just up` with a private helper that restarts the registered `d20` watcher through the active configuration file or starts `serve` when the node is absent.
- [x] 1.2 Remove the now-unused conditional Linux `procps` dependency from the Nix development shell.

## 2. Validation

- [x] 2.1 Verify the private helper is hidden, the `up` recipe renders the intended order, and exact node-name matching excludes similar names.
- [x] 2.2 Verify Linux and macOS flake evaluation and run strict OpenSpec validation.

## 3. Directory-Wide Restart Scope

- [x] 3.1 Remove per-file watcher filters so every change below `envs/` or `config/` can trigger replacement.
- [x] 3.2 Verify rendered watcher arguments contain only the intended directory roots and run strict OpenSpec validation.
