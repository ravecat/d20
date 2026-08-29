## 1. One-line takeover

- [x] 1.1 Provide `pkill` through `pkgs.procps` on Linux and the system utility on macOS.
- [x] 1.2 Replace EPMD and `erl_call` logic with one exact short-name `pkill` command.
- [x] 1.3 Preserve `--exit-on-error`, custom arguments, foreground IEx, and all four watch roots.

## 2. Documentation and specifications

- [x] 2.1 Remove EPMD, RPC, cookie, and timeout behavior from README and authoritative specifications.
- [x] 2.2 Document forceful local takeover, exact-name matching, and the one-time legacy watcher transition.

## 3. Validation

- [x] 3.1 Validate Just parsing, Nix evaluation for Linux and macOS, and strict OpenSpec rules.
- [x] 3.2 Verify absent, repeated watched, direct, custom, partial-name, and configuration restart behavior.
- [x] 3.3 Verify latest-terminal IEx input, cleanup, and the relevant repository checks.

## 4. Reconciliation and archive

- [x] 4.1 Reconcile GitHub issue #244 and authoritative specifications with verified behavior.
- [x] 4.2 Archive the completed change and rerun strict lifecycle validation.
