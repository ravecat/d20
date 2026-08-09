## Context

Each `D20.Game` engine already returns an Ecto changeset for session creation input. `D20Web.PageController` currently passes that changeset through `D20.Form`, which produces a D20-specific field descriptor consumed by the Svelte game page. Koala Rescue Club uses an `Ecto.Enum` field with `:dharug` in the changeset data, while Next Station London uses two boolean fields with `false` in the data.

Schemecto can convert the existing runtime changeset directly to JSON Schema for its supported Ecto types and validation metadata. It does not export `changeset.data`, so the page boundary must add that new-session data as the schema's root `default` annotation. These forms only create sessions and never edit existing values, so the changeset data represents declarative defaults rather than a current form instance. This spike is tracked by issue #26 and intentionally evaluates the smallest Ecto-first replacement before introducing a schema-first server DSL.

## Goals / Non-Goals

**Goals:**

- Replace the bespoke game launch field descriptor with a standard JSON Schema transport.
- Preserve game-defined creation defaults from the changeset data in the generated schema.
- Exercise the contract end to end for the current enum and boolean launch forms.
- Use a library-owned Svelte renderer rather than maintaining JSON Schema interpretation in D20.
- Preserve the request payload, processing state, server errors, and authoritative game changesets through the Inertia router.
- Make the Schemecto dependency reproducible by pinning an exact commit.
- Remove the obsolete projected setup-attrs path from the waiting-room client after moving setup to session creation.

**Non-Goals:**

- Do not replace game changesets with Peri, Gladius, embedded schemas, or another schema-first definition.
- Do not accept backend-provided UI Schema, field ordering, groups, localized field labels, or conditional visibility.
- Do not claim support for arbitrary Ecto custom types, custom validations, embeds, arrays, or nested error paths.
- Do not change session creation, game initialization, runtime, channel, or persistence contracts.

## Decisions

1. The controller exposes the generated schema directly as the `schema` page prop.

   For a launchable game, `PageController` obtains one empty-params changeset and constructs:

   ```elixir
   changeset = D20.Game.changeset(entry.engine)

   schema = to_schema(changeset)

   defp to_schema(changeset) do
     defaults = Map.take(changeset.data, Map.keys(changeset.types))

     changeset
     |> Schemecto.to_json_schema()
     |> Map.put("default", defaults)
   end
   ```

   Taking only keys present in `changeset.types` avoids exposing unrelated struct or map data. The private helper keeps JSON Schema transport policy at the web boundary and returns the schema itself, avoiding both a transport wrapper and an ambiguous public `D20.Game.to_schema/1` API.

   Alternative considered: keep `D20.Form` as a wrapper around Schemecto. That adds an application module without adding policy or reuse, while the spike specifically tests whether the dependency can eliminate the custom serializer.

2. The schema carries creation defaults through standard JSON Schema.

   The page sends the map returned by `Schemecto.to_json_schema/1` directly as `schema`, after adding the filtered changeset data as the root `default`. It does not add UI keywords or property ordering. SJSF merges schema defaults into its initial form state, so no parallel value contract is required.

   Alternative considered: keep a separate `initial` member. That is appropriate for editing an existing instance, but these forms only create new sessions, so it duplicates data that JSON Schema already describes with `default`.

3. SJSF owns JSON Schema interpretation and control rendering.

   The Svelte page renders a focused launch-form component only when the controller supplies a schema. That component receives the page `schema` prop and creates the local SJSF `form` without an `initialValue`. SJSF uses its basic component set, applies schema defaults, chooses default widgets, and derives fallback field labels from property names. The component supplies only a shell-owned root UI translation override for the `Play` submit label. Enum presentation and property order remain library defaults rather than D20 policy.

   A shared form adapter stylesheet builds on the SJSF basic stylesheet and maps its stable public classes to the shell's DaisyUI theme tokens. It styles the generated controls, focus, error, disabled, and submit states without replacing SJSF markup or interpreting individual schema properties.

   Alternative considered: retain a small renderer that branches on `enum`, `boolean`, and primitive types. That leaves D20 responsible for schema semantics and edge cases, which contradicts the purpose of adopting a standard form description.

4. SJSF owns the HTML form and Inertia owns the request lifecycle.

   The page does not nest SJSF inside Inertia's `<Form>`. SJSF invokes an `onSubmit` callback with the typed object, and that callback posts the same flat attrs to `POST /games/:slug/sessions` with the Inertia router. The adapter exposes router processing state through the form's disabled option and maps server field errors to SJSF field paths. SJSF replaces its error store on the next validation, so D20 does not maintain a parallel server-error registry. The server changeset remains authoritative even when SJSF performs client validation.

   Alternative considered: keep Inertia `<Form>` around SJSF output. Both components own a `<form>` and intercept submission, so nesting them would produce invalid HTML and conflicting form state.

5. Dependencies are reproducible and aligned with the existing frontend stack.

   Add Schemecto from `josevalim/schemecto` at commit `f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656`. The repository currently has no Hex release or tags, so following its default branch would make builds non-reproducible.

   Add compatible released versions of `@sjsf/form`, `@sjsf/basic-theme`, `@sjsf/ajv8-validator`, and AJV. The basic theme supplies the mandatory SJSF component implementations, and the thin shared adapter aligns them with existing product tokens. AJV applies JSON Schema semantics with native validation disabled, avoiding the HTML checkbox interpretation where `required` means checked rather than property present.

   The shared SJSF defaults register `createFormIdBuilder` as the value of the library's required `idBuilder` option. The factory name is not itself a recognized form option; using it as an object key leaves the internal ID builder undefined and causes the launch page to fail before rendering any controls.

   Exclude the Svelte-bearing form and basic-theme packages from Vitest dependency pre-bundling so the configured Svelte plugin compiles their published `.svelte` modules in browser tests.

6. Contract tests cover behavior rather than full schema snapshots.

   Controller tests assert the relevant object type, properties, enum values, required fields, and root defaults for current games. Svelte tests assert that SJSF renders controls from the schema, applies defaults, submits typed values through Inertia, and surfaces server errors. This avoids coupling tests to property order, generated markup details, or unrelated future Schemecto output.

   Type checking is part of the regression boundary because SJSF's `FormOptions` contract reports a missing `idBuilder` before the equivalent runtime `undefined.fromPath` failure.

7. The waiting-room Start action has no setup attrs.

   Game-specific setup is submitted by the launch form before the session is created. Session projections do not contain an `attrs` field, so the client removes `AttrConfig`, `Attrs`, `Session.attrs`, and the descriptor-driven setup controls from the waiting room. The Start channel command continues to send an empty object because game start commands currently expect no user-provided attrs.

## Risks / Trade-offs

- [Risk] Schemecto silently ignores unsupported validation metadata. -> Limit the spike to current supported validations, document the gap, and retain the server changeset as authoritative.
- [Risk] Creation defaults can contain values that are not JSON encodable. -> Filter them to declared changeset fields and cover the current enum and boolean values in controller tests; broader type support remains outside the spike.
- [Risk] JSON Schema does not fully specify widget choice, layout, or product wording. -> Accept SJSF basic defaults for the spike and introduce UI Schema only when a game has a concrete presentation requirement.
- [Risk] Map property order is not a product contract. -> Accept dependency-provided order for the spike and do not test or document ordering.
- [Risk] SJSF can change its basic theme class contract in a later release. -> Keep the dependency pinned by the frontend lockfile and validate the rendered launch page when upgrading it.
- [Risk] An unreleased dependency can change or become unmaintained. -> Pin the reviewed commit and keep rollback limited to restoring the removed serializer.

## Migration Plan

1. Add the pinned Mix dependency and lock it.
2. Change the controller page prop from `attrs` to a self-contained `schema` prop with a root `default`.
3. Add SJSF's basic components and AJV validator, then update Svelte types, fixtures, and rendering to consume the new contract.
4. Remove `D20.Form`, the client `AttrConfig` projection path, and their focused tests.
5. Run controller, game page, formatting, lint, type, dependency, and broad repository validation.

Rollback restores `D20.Form`, the `attrs` page prop and fixtures, then removes Schemecto and the SJSF packages. No data or runtime migration is required.

## Open Questions

None block the spike. Adoption beyond the current primitive fields requires a follow-up decision on unsupported validation detection and a library-owned Svelte renderer.
