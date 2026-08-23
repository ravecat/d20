## 1. Module-Owned Sandbox Policy

- [x] 1.1 Add the current non-empty `allow-scripts` and `allow-same-origin` policy to `D20Web.Module` application configuration in `config/config.exs`.
- [x] 1.2 Change `D20Web.Module.entry/2` to resolve and validate the module-owned policy, preserve registry-gated slug URL derivation, and return the existing descriptor shape unchanged.
- [x] 1.3 Make the focused module tests safely replace and restore shared application configuration, prove configured values are used for both connection-source forms, and cover missing and malformed policies.

## 2. Registry Boundary Cleanup

- [x] 2.1 Remove `sandbox` from every configured game registry entry and from `D20.Games.Registry.Entry` fields, embedded types, struct, public type, and validation.
- [x] 2.2 Keep active and in-progress registry validation dependent on a valid engine only, while preserving inactive entry, slug, BGG id, status, lookup, and invalid-engine behavior.
- [x] 2.3 Update registry tests to assert the reduced entry contract and remove obsolete sandbox exposure and validation cases.

## 3. Integration Fixtures and Contract Preservation

- [x] 3.1 Remove registry-owned sandbox values from controller, page-controller, workspace-channel, and other focused test fixtures that construct or override game entries.
- [x] 3.2 Retain assertions that workspace descriptors expose the current sandbox list and that embed URLs, allowed origins, channel endpoint/topic/token data, launch behavior, and unknown-game rejection remain unchanged.
- [x] 3.3 Confirm `priv/specs/workspace.yaml` and the frontend `ModuleEntry`/iframe behavior require no edits because the public descriptor contract is unchanged.

## 4. Validation and Delivery

- [x] 4.1 Format touched Elixir and configuration files with `mix format <files>` and run targeted registry, module, module-controller, page-controller, and workspace-channel tests.
- [x] 4.2 Run the full backend suite with `mix test` and the repository-wide checks with `just check`, recording any unrelated failures separately.
- [x] 4.3 Run `openspec validate centralize-module-sandbox-policy --strict --no-interactive`, then archive the completed change, run `openspec validate --all --strict --no-interactive`, and confirm `centralize-module-sandbox-policy` is absent from `openspec list --json`.
