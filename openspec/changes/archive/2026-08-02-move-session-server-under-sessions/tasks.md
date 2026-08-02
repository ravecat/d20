## 1. Runtime Ownership

- [x] 1.1 Move the shared runtime module to `D20.Sessions.Server` and make it the default selected by `D20.Game`.
- [x] 1.2 Update repository custom Session servers to use the renamed shared runtime.
- [x] 1.3 Remove `attach/2` and `detach/2` from the server behaviour, generated delegates, wrappers, and overridable interface while retaining Session-process event handling.

## 2. Contracts and Coverage

- [x] 2.1 Update architecture guidance and current durable specifications to name the Session-owned runtime.
- [x] 2.2 Update focused runtime and custom-server tests for the renamed module and narrowed callback contract.
- [x] 2.3 Confirm maintained implementation, tests, guidance, and current specifications contain no `D20.Game.Server` references.

## 3. Validation

- [x] 3.1 Format touched Elixir files and run focused Session, game, custom-server, and Workspace tests.
- [x] 3.2 Run `just check` and strict OpenSpec validation.
