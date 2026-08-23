## Context

`config/config.exs` currently repeats `sandbox: ["allow-scripts", "allow-same-origin"]` on Fliptown, Koala Rescue Club, Next Station: London, and Qwinto. `D20.Games.Registry.Entry` stores and validates that list, and `D20Web.Module.entry/2` copies it into the caller-facing module descriptor. The Svelte frame then joins the descriptor list into the iframe `sandbox` attribute.

All configured module policies are identical. The sandbox grants control browser capabilities of shell-owned iframes; they do not identify games, bind engines, resolve BGG metadata, or describe game rules. `D20Web.Module` already owns embed URL/origin derivation and channel connection data, so it is the narrowest existing boundary that can own the framing policy without introducing another module.

The public descriptor must continue to contain `sandbox`, because `assets/js/widgets/workspace/ui/frame.svelte` consumes it directly. Registry lookup must also continue to gate descriptor creation for known games.

## Goals / Non-Goals

**Goals:**

- Give the shell one authoritative iframe sandbox policy.
- Remove browser framing policy from game registry configuration, types, and validation.
- Preserve the current effective iframe capabilities and module descriptor shape.
- Fail explicitly rather than emit a malformed descriptor when module sandbox configuration is absent or invalid.
- Keep unknown games behind the existing registry lookup boundary.

**Non-Goals:**

- Add or remove iframe capabilities.
- Introduce per-game, per-origin, per-environment, or version-negotiated capability policies.
- Change embed URL derivation, allowed origins, channel endpoint/topic/token claims, session lifecycle, or frontend behavior.
- Add CSP, Permissions Policy, sandbox reporting, or changes to separately delivered game repositories; those remain in GitHub issue #108.

## Decisions

### 1. Configure one policy under `D20Web.Module`

Add `config :d20, D20Web.Module, sandbox: ["allow-scripts", "allow-same-origin"]` beside the registry and module-token configuration. `D20Web.Module.entry/2` will resolve that value through a private configuration helper and place it unchanged in the descriptor.

A global policy is intentional: every current module receives the same grants, the shell owns the iframe, and no repository behavior demonstrates a per-game capability difference. Keeping a map keyed by slug would reproduce the registry duplication in a second location. A future versioned capability model can replace the single list under issue #108 when distinct policies have concrete requirements.

### 2. Validate configuration at the module framing boundary

The private sandbox resolver will require a non-empty list containing only strings. Missing configuration will fail through `Application.fetch_env!/2` or `Keyword.fetch!/2`; malformed configuration will raise an explicit configuration error before a descriptor reaches the client.

Blindly returning `Application.get_env/3` with a permissive default was rejected because it could silently remove or broaden browser isolation. Compile-time configuration was rejected because runtime application configuration is already the repository pattern for registry data and a focused test must be able to prove that descriptor generation consumes the configured value rather than a hard-coded constant.

### 3. Remove `sandbox` completely from `D20.Games.Registry.Entry`

Remove the field from the Ecto embedded types, cast fields, struct, type, non-empty validation, and operational-binding validation. Active and in-progress entries will continue to require a valid engine binding; inactive catalog entries will continue to require only slug and BGG id.

Retaining a deprecated or ignored registry field was rejected because the repository does not require backward compatibility and two apparent sources of truth would preserve the ownership error. Configured game entries and test fixtures will therefore remove the field in the same change.

### 4. Preserve the external module descriptor

`D20Web.Module.entry/2` will continue accepting a `D20.Games.Registry.Entry` so the slug and existing registered-game gate remain unchanged. Only its struct match changes from `slug + sandbox` to `slug`; its returned map still contains `embed_url`, `allowed_origins`, and `sandbox`. `D20Web.Workspace` and the frontend module interface require no production changes.

Moving `sandbox` into channel connection data was rejected because browser iframe capabilities are frame metadata, not credentials or SessionChannel bootstrap data.

### 5. Prove ownership at the closest tests

Registry tests will assert that entries and operational validation no longer contain `sandbox`. Module tests will temporarily replace and restore `D20Web.Module` application configuration, assert that both connection sources project the configured list, and cover invalid configuration. Because application environment is shared state, those tests must be non-async. Existing workspace/channel and controller fixtures will drop registry sandbox values while retaining descriptor assertions for the unchanged default policy.

Frontend tests and source do not need changes because the descriptor contract and iframe assignment remain unchanged. Broad validation will still detect an accidental contract drift.

## Risks / Trade-offs

- [A future module needs different capabilities] -> Keep the current policy global until a concrete capability contract exists; extend the module-owned configuration under #108 rather than restoring policy to the game registry.
- [Invalid configuration now fails when a descriptor is built] -> Validate explicitly and cover missing, empty, non-list, and non-string values at the module boundary.
- [Shared application environment can make tests race] -> Mark configuration-mutating module tests `async: false` and restore the original value in `on_exit/1`.
- [Removing the registry field touches many fixtures] -> Update only fixtures that currently supply `sandbox`, then run focused registry, module, controller, page-controller, and workspace-channel tests before the full suite.
- [The global setting could appear to authorize unknown games] -> Preserve registry lookup as the prerequisite for every production descriptor path; the policy alone does not discover or launch a module.

## Migration Plan

1. Add the `D20Web.Module` sandbox configuration with the currently effective values.
2. Make module descriptor generation read and validate that configuration while its public result remains unchanged.
3. Remove `sandbox` from registry configuration, `Registry.Entry`, validation, and fixtures.
4. Run focused and broad validation, then archive and synchronize the OpenSpec change according to repository policy.

No data migration or coordinated deployment with game clients is required. Rollback restores the per-entry values and registry field/validation, then changes `D20Web.Module.entry/2` back to copying the entry value. Because both directions preserve the descriptor shape and effective grants, rollback does not require a frontend or separate-module release.

## Open Questions

None.
