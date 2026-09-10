## Context

The repository exposes manually owned gameplay guidance and a dependency-managed Phoenix skill. Shell implementation currently relies on dispersed `AGENTS.md` rules and nearby code. `lib/d20/games/game.ex` demonstrates an entity-specific TypeID, named `id()` type, and separate creation/update changesets; its migration stores the identifier as a string.

The user's primary-key request is interpreted from the cited `@primary_key` declaration. GitHub issue #277 owns this documentation outcome. The user explicitly authorized authoring in the primary checkout on `master`; the coordinator restored its previous commit before this change began.

## Goals / Non-Goals

**Goals:**

- Make shell feature work discoverable through one concise, manually owned skill.
- Define verifiable gates for ownership, authorization, persistence, contracts, validation, and completion.
- Require typed TypeID primary keys and explicit creation changesets for new persisted shell entities.

**Non-Goals:**

- Change application behavior or retrofit existing schemas and runtime IDs.
- Duplicate game rules, framework documentation, or the full root repository policy.
- Introduce new runtime dependencies, migrations, or external iframe repository work.

## Decisions

1. Add `.agents/skills/implement-shell-feature/SKILL.md` and compact `agents/openai.yaml` metadata following the existing local skill layout. Link it from the root task-routing and manual-ownership guidance. A dedicated skill gives shell implementation a focused trigger; expanding the already large gameplay skill would mix different ownership boundaries.
2. Organize the workflow around gates: tracking and ready OpenSpec; domain ownership and caller authorization; persistence when needed; implementation and public contracts; relevant validation; reconciliation and archive. Reference root guidance and existing sources rather than reproduce them. Gameplay routes to `implement-playable-game`; generic session work continues through `D20.Sessions`.
3. For each new persisted shell entity, require `@primary_key {:id, TypeID, autogenerate: true, prefix: "entity"}`, an entity-specific stable prefix, `@type id :: TypeID.t()`, and `id: id()` in `t()`. Require a matching string primary-key migration and compatible foreign keys. Ecto performs TypeID autogeneration; the guidance must not assume a database default. Preserve existing runtime IDs, and mark the persistence gate inapplicable for changes that introduce no persisted entity.
4. Require schema `create_changeset` functions to validate permitted creation attributes and be invoked by actual insertion paths. Derive trusted ownership and caller identity separately from request attributes. Separate creation and update policies when immutable fields differ. Require database constraints, mapped changeset errors, and concurrency/retry decisions where the behavior needs them. A function that exists but is bypassed does not satisfy the gate.
5. Verify this documentation delivery with skill validation, a review against relevant repository sources and representative tasks, `git diff --check`, and strict OpenSpec validation. Do not run application tests solely for a documentation addition. The skill itself directs future implementations to native Mix/Bun checks and browser validation when their changed behavior warrants them.

## Risks / Trade-offs

- Overgeneralizing a persisted schema example to runtime aggregates could change established IDs. Limit the mandatory identity rule to new persisted shell entities and state the existing-contract boundary explicitly.
- Copying the reference schema's prose could imply SQL generates TypeIDs. Name Ecto as the generator and check the migration representation directly.
- Duplicated repository rules can drift. Keep the skill short, link authoritative sources, and extend the existing manual-ownership requirement rather than add generation machinery.

## Migration Plan

No database or runtime migration is needed. Add the skill and routing guidance, reconcile tasks, synchronize specification deltas through the native archive workflow, validate, and commit the documentation together. Revert the same files together if the guidance must be withdrawn.

## Open Questions

None. The interpretation of the requested key follows the exact schema declaration linked by the user.
