# Dynamic game session forms with Phoenix and Inertia

Research date: 2026-08-08

Scope: server-described game session creation forms in the D20 Phoenix, Inertia, and Svelte stack

Tracking issue: [#26 Players Can Create and Join Sessions on Supported Viewports](https://github.com/ravecat/d20/issues/26)

## Decision

[Schemecto](https://github.com/josevalim/schemecto) is the one concrete library found that accepts an already-built `%Ecto.Changeset{}` and derives JSON Schema from its supported `types`, `required`, and `validations`. The current D20 schemaless changesets can be passed to `Schemecto.to_json_schema/1` without replacing them with another schema DSL.

For D20's current simple game launch forms, the least disruptive library path is:

- keep `D20.Game.changeset/1` as the authoritative server parser and validator;
- derive the portable subset with `Schemecto.to_json_schema/1`;
- add the filtered new-session changeset data as the schema's root `default`, because these forms never edit an existing instance;
- render the schema with [`@sjsf/form`](https://x0k.dev/svelte-jsonschema-form/) and introduce UI Schema only when a concrete presentation requirement needs it;
- submit SJSF's typed value with the Inertia router and map Inertia server errors back into SJSF's error state.

Schemecto is not yet a safe project-wide dependency: it has no Hex release or version tags, unknown validations are silently omitted, and its nesting model uses package-specific parameterized types. Use a pinned-commit two-game spike and contract tests before adoption.

If D20 requires a released dependency and fail-closed JSON Schema generation, move the game attribute definition one level above the changeset with [Peri](https://peri.hexdocs.pm/). Peri can generate both an Ecto schemaless changeset and JSON Schema, but this changes the source of truth instead of adapting the existing changeset.

Two other alternatives are technically credible but not the default recommendation:

- [Gladius](https://github.com/Xs-and-10s/gladius) has ordered runtime schemas, Ecto changeset generation, nested embed support, recursive error traversal, coercion, and JSON Schema 2020-12 export. It is a stronger feature match for deeply nested forms, but it is very new and has little production adoption.
- A strict D20 adapter could project a supported Ecto subset to JSON Schema and raise on everything else. This is safer than Schemecto's silent fallback but keeps server conversion code in D20.

If hand-written Ecto changesets must remain the source of truth, the fallback is a thin `D20.Form` JSON Schema projection built only from public Ecto and Phoenix reflection APIs, followed by SJSF rendering. There is no supported package that removes that final server-side adapter for arbitrary schemaless changesets.

Inertia has no special dynamic-form schema. It remains the page transport and request mechanism after SJSF renders the controls. [Inertia forms](https://inertiajs.com/docs/v3/the-basics/forms)

The least disruptive boundary for the existing code is:

```text
   existing game changeset
          /       \
         v         v
 server validation  Schemecto
                       |
                       v
                  JSON Schema
              + creation defaults
                       |
                       v
                Svelte rendering
                       |
                       v
                Inertia submit
```

## Why `to_form/2` is not a serialized browser form

`Phoenix.Component.to_form/2` converts a map or changeset into `%Phoenix.HTML.Form{}` for Phoenix form components. It does not return the browser `FormData` interface and does not define a JSON wire contract. [Phoenix `to_form/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#to_form/2), [Phoenix.HTML.FormData](https://hexdocs.pm/phoenix_html/Phoenix.HTML.FormData.html)

The struct contains server-side implementation details including `source`, `impl`, `data`, `params`, `errors`, and rendering options. On the dependency versions locked by D20, attempting to encode it directly with Jason raises `Protocol.UndefinedError`. Adding a Jason encoder would only hide the boundary problem:

- the representation is owned by Phoenix HTML, not by D20;
- it contains data that the client does not need;
- it can change with dependency implementation details;
- it still does not say whether a string should be a text field, password, email, textarea, or another widget;
- it does not provide field order, labels, help text, groups, localized option labels, or visibility rules.

The useful operation is not serialization of the struct. It is projection from the form and changeset into an application-owned JSON shape.

## What can be derived safely

The following data can be derived without duplicating validation rules on the client:

| Client fact | Phoenix or Ecto source | Limitation |
| --- | --- | --- |
| Input id and name | `form[field].id`, `form[field].name`, or `Phoenix.HTML.Form.input_id/2` and `input_name/2` | The outer parameter namespace remains an application decision. |
| Current value | `Phoenix.HTML.Form.input_value/2` | Submitted params can be strings even when the Ecto type is boolean or numeric. Normalize only for the chosen HTML control. |
| Required status | `Phoenix.HTML.Form.input_validations/2` | This is an HTML hint. The server changeset remains authoritative. |
| Common length and number constraints | `Phoenix.HTML.Form.input_validations/2` | `phoenix_ecto` currently projects only supported HTML validations such as `required`, `minlength`, `maxlength`, `min`, `max`, and `step`. It is not every changeset validation. |
| Ecto type | `changeset.types[field]` | An Ecto type does not uniquely determine a UI widget. |
| Enum values and dumped mappings | `Ecto.Enum.values/2` or `Ecto.Enum.mappings/2` | Labels and whether to use radio buttons or a select remain presentation decisions. |
| Validation errors | `Inertia.Controller.assign_errors/2` | Errors should be response state, not static field-schema metadata. |

`Phoenix.HTML.Form.input_validations/2` is the public Phoenix API for obtaining applicable HTML validation attributes. In D20's `phoenix_ecto` 4.7.0 implementation, required, length, and number validations are mapped to HTML attributes. [Phoenix input validations](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#input_validations/2), [phoenix_ecto implementation](https://github.com/phoenixframework/phoenix_ecto/blob/v4.7.0/lib/phoenix_ecto/html.ex)

For enums, use the public `Ecto.Enum.values/2` or `Ecto.Enum.mappings/2` API. Both accept a schema or a schemaless changeset types map. This avoids matching the internal parameterized Ecto type representation. [Ecto.Enum mappings](https://hexdocs.pm/ecto/Ecto.Enum.html#mappings/2)

## What must remain explicit game metadata

The changeset answers whether external data can become valid game initialization attributes. It does not fully answer how a human should enter those attributes.

Each game must explicitly decide any presentation fact that cannot be derived unambiguously:

- stable field order;
- `text`, `textarea`, `number`, `checkbox`, `radio`, or `select` widget choice;
- labels and descriptions;
- localized labels for enum values;
- sections and groups;
- disabled or read-only presentation;
- conditional visibility and dependencies between fields;
- placeholders, input modes, and autocomplete intent;
- accessibility relationships beyond the generated id and error key.

This metadata should stay small. D20 does not need a generic no-code form platform. It needs enough variants to render the actual game initialization attributes, and unsupported types should fail clearly instead of silently falling back to a string input.

## Library evaluation

### Result

There is no end-to-end Phoenix, Ecto, Inertia, and Svelte package that removes every application boundary. The direct chain for the existing D20 changesets is:

```text
Ecto changeset -> Schemecto -> JSON Schema -> @sjsf/form -> Inertia router
```

The released schema-first alternative is:

```text
Peri schema -> Ecto changeset + JSON Schema -> @sjsf/form -> Inertia router
```

The first chain requires less migration but accepts a new, unversioned dependency. The second chain is more mature and can fail on unsupported schema features, but requires replacing the hand-written changeset definition as the source of truth.

Registry status was checked on 2026-08-08 against the packages' official Hex, npm, documentation, and source repositories:

| Package | Current status | What it provides | D20 fit |
| --- | --- | --- | --- |
| [Peri 0.9.1](https://hex.pm/packages/peri) | Released 2026-08-07, pre-1.0, 38 published versions | One Elixir schema can produce an Ecto schemaless changeset and JSON Schema Draft 7. | Best server-side fit if D20 accepts Peri as the game input source of truth. |
| [Gladius 0.6.0](https://hex.pm/packages/gladius) | Released 2026-04-07, pre-1.0, very low adoption | Ordered runtime schemas, Ecto changesets, nested embeds, recursive errors, and JSON Schema 2020-12 export. | Feature-rich alternative, but currently a higher dependency risk than Peri. |
| [Schemecto](https://github.com/josevalim/schemecto) | GitHub-only, no package or release tags | Dynamic schemaless Ecto changesets, nesting, field metadata, and JSON Schema generation from supported Ecto validations. | Closest Ecto-first option, but not mature enough to make the project standard. |
| [`@sjsf/form` 3.8.0](https://www.npmjs.com/package/@sjsf/form) | Published 2026-07-25, requires Svelte 5 | Runtime JSON Schema form generation, UI Schema, dynamic branches, validation, themes, and custom components. | Best client renderer and compatible with D20's Svelte 5 runtime. |
| [`@sjsf/daisyui5-theme` 3.8.0](https://www.npmjs.com/package/@sjsf/daisyui5-theme) | Published 2026-07-25, requires daisyUI 5 and Svelte 5 | Ready SJSF control and layout implementations for daisyUI 5. | Directly matches D20's existing UI stack and avoids a custom theme for common controls. |
| [AshPhoenix 2.3.24](https://hex.pm/packages/ash_phoenix) | Released 2026-07-08 | Rich Phoenix form lifecycle for Ash resource actions and nested relationships. | Not a changeset-to-JSON-schema adapter and would require moving D20 game inputs to Ash resources and actions. |
| [OpenApiSpex 3.22.3](https://hex.pm/packages/open_api_spex) | Released 2026-05-05 | Manually declared OpenAPI 3 schemas, request casting, validation, and API documentation. | Useful when OpenAPI is already the source of truth, but it does not derive a schema from an Ecto changeset or select Svelte widgets. |
| [Ostara 0.4.4](https://hex.pm/packages/ostara) | Last released 2024-10-21, pre-1.0 | Converts Ecto schema modules and a limited set of changeset calls to JSON Schema. | Reject for D20: it requires an `Ecto.Schema` module, reads changeset source AST, has limited validation coverage, and does not support D20's arbitrary schemaless changesets. |
| [`svelte-formly` 2.0.1](https://www.npmjs.com/package/svelte-formly) | Last published 2022-07-24 | Config-driven Svelte form renderer. | Reject: its published package targets the Svelte 3 toolchain and predates D20's Svelte 5 stack. |
| [Felte 1.3.0](https://www.npmjs.com/package/felte) | Last published 2024-10-29, supports Svelte 5 | Form state, submission, validation adapters, and runtime addition or removal of controls. | Valid standalone form-state library, but it does not generate controls from JSON Schema, so D20 would still own the renderer. It also overlaps Inertia and SJSF state management. |
| [Superforms 2.30.2](https://www.npmjs.com/package/sveltekit-superforms) | Published 2026-07-04 | SvelteKit form actions, validation adapters, client state, and SPA mode. | Poor fit: it has a SvelteKit peer dependency and expects SvelteKit actions or `ActionResult` semantics. It does not render fields from a runtime schema. |
| [Formsnap 2.0.1](https://www.npmjs.com/package/formsnap) | Last published 2025-04-09 | Accessible field composition primitives on top of Superforms. | Poor fit: it requires Superforms, does not render runtime schemas, and would duplicate D20's Inertia integration. |
| [JSON Forms](https://jsonforms.io/) | Active JSON Schema form framework | JSON Schema plus UI Schema, rules, and a renderer registry. | No official Svelte renderer. D20 would have to implement and maintain the Svelte renderer set. |
| [SurveyJS Form Library](https://surveyjs.io/form-library/documentation/overview) | Mature MIT runtime form engine | Large control set, conditions, validation, and JSON-defined surveys for vanilla JavaScript and major UI frameworks. | Complete but uses its own survey model, has no official Svelte integration, and is much broader than game launch settings. |
| [Form.io renderer](https://help.form.io/developers/form-renderer) | Mature form platform and renderer | JSON-defined form builder, renderer, workflows, submissions, and platform services. | Heavy platform adoption with a proprietary form schema; it duplicates validation and lifecycle responsibilities already owned by Phoenix. |

Release recency is only a maintenance signal, not a quality guarantee. The API and architecture fit is decisive here.

### Phoenix.HTML.FormData and Ecto reflection

`Phoenix.HTML.FormData` is the standard protocol for adapting a data structure to `%Phoenix.HTML.Form{}`. Its documented callbacks produce form structs, nested form structs, input values, and HTML validation attributes. It is deliberately a low-level server rendering protocol, not a JSON Schema protocol. [Phoenix.HTML.FormData](https://phoenix-html.hexdocs.pm/Phoenix.HTML.FormData.html)

Ecto exposes enough public reflection for a narrow adapter:

- `changeset.types` and `changeset.required` are public fields;
- `Ecto.Changeset.validations/1` exposes validation metadata but explicitly says the possible values are not exhaustive;
- `Phoenix.HTML.Form.input_validations/2` maps the validations supported by `phoenix_ecto` to HTML attributes;
- `Ecto.Enum.values/2` and `Ecto.Enum.mappings/2` expose enum values through a public API.

These APIs can produce a useful subset of JSON Schema, but they cannot infer UI intent or faithfully encode arbitrary custom, cross-field, database-backed, or conditional validations. [Ecto changeset reflection](https://ecto.hexdocs.pm/Ecto.Changeset.html#validations/1), [Phoenix input validations](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#input_validations/2), [Ecto.Enum mappings](https://hexdocs.pm/ecto/Ecto.Enum.html#mappings/2)

### AshPhoenix.Form

`AshPhoenix.Form` is a maintained and capable form model, but it solves a different problem. It creates and submits forms for Ash resource actions, handles nested relationship forms, and implements Phoenix form behavior. Its documented lifecycle renders through Phoenix components or LiveView and submits through Ash actions. It does not document a portable JSON Schema or Inertia serializer. [AshPhoenix.Form](https://ash-phoenix.hexdocs.pm/AshPhoenix.Form.html)

Adopting it only for game launch attributes would require introducing Ash resources and actions around a domain that currently uses small schemaless Ecto changesets. That is a larger architectural replacement than the form problem justifies.

### What can consume an already-built Ecto changeset

[Schemecto](https://github.com/josevalim/schemecto) is the one concrete library found that accepts an already-built `%Ecto.Changeset{}`. `Schemecto.to_json_schema/1` pattern matches only `types`, `required`, and `validations`, so the changeset does not have to originate from `Schemecto.new/2`. D20's current `Game.changeset(%{})` can therefore be passed directly for its supported primitive types, arrays, `Ecto.Enum`, `validate_required`, format, inclusion, length, number, and subset validations. [Schemecto conversion source](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/lib/schemecto.ex#L198-L358)

For the current Koala Rescue Club launch changeset, the intended experiment is as small as:

```elixir
changeset = D20.KoalaRescueClub.Game.changeset(%{})
json_schema = Schemecto.to_json_schema(changeset)
```

This should produce an object schema whose `sheet` property is a string enum and whose required list contains `sheet`. It does not require replacing the existing changeset with Peri or with `Schemecto.new/2`.

The important limitations are visible in Schemecto's implementation:

- unknown validation metadata is silently ignored, so `validate_change`, custom and cross-field functions, database constraints, and application-specific validation tuples do not fail schema generation;
- defaults are stored in the schemaless changeset data by `Schemecto.new/2`, but `to_json_schema/1` does not read `changeset.data`, so it does not currently emit JSON Schema `default` values;
- title, description, and deprecated metadata are available only when inserted through Schemecto's field definition format; an arbitrary existing changeset does not carry those presentation annotations;
- ordinary Ecto embeds are not handled by the converter; nesting is implemented through Schemecto's own `Schemecto.One` and `Schemecto.Many` parameterized types;
- nested validation errors are returned from those parameterized types as cast error metadata rather than ordinary child changesets, so standard nested `Ecto.Changeset.traverse_errors/2` and Inertia error paths need a focused integration test;
- `$schema` is intentionally omitted and must be added by the caller; the documentation recommends JSON Schema 2020-12.

These are package behavior facts, not theoretical limitations. The converter's catch-all clause ignores unsupported validations, while the nested types return their child errors in the parameterized type's `{:error, metadata}` result. [Schemecto validation source](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/lib/schemecto.ex#L305-L358), [Schemecto nested-one source](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/lib/schemecto/one.ex#L13-L33), [Schemecto nested-many source](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/lib/schemecto/many.ex#L20-L62)

Schemecto is therefore a real Ecto-first answer for D20's current simple form subset, but not yet a safe universal `changeset -> JSON Schema` boundary. Its README still installs directly from the GitHub `main` branch, the repository has no version tags or releases, and the declared `0.1.0` has not been published to Hex. A spike should pin the exact commit and add contract tests that make unsupported changeset validations fail in D20 instead of accepting Schemecto's silent omission. [Schemecto installation](https://github.com/josevalim/schemecto#installation), [Schemecto package metadata](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/mix.exs)

### Ecto schema and source-code analyzers

OpenApiSpex provides `%OpenApiSpex.Schema{}` and request casting and validation, but its schemas are declared explicitly. Its documentation describes the schema object as an extended subset of JSON Schema used by OpenAPI 3. It does not derive those schemas from Ecto changesets. Using it would replace one manual form contract with a manual API contract, while SJSF would still need UI Schema metadata. [OpenApiSpex schemas](https://hexdocs.pm/open_api_spex/OpenApiSpex.Schema.html)

Ostara is the closest released Hex package that starts from Ecto, but its input is an `Ecto.Schema` module, not a `%Ecto.Changeset{}`. `Ostara.transmute(Module)` reflects on `Module.__schema__/1`, then reads the module's source file and pattern matches the AST of a directly defined `changeset` function. Its validation extractor has explicit clauses for required fields, required embeds, numeric bounds, and length, while unrecognized calls only produce a warning. That excludes D20's runtime schemaless changesets and is fragile around helper functions, control flow, custom validations, dynamically composed field lists, and source-unavailable releases. [Ostara documentation](https://hexdocs.pm/ostara/readme.html), [Ostara validation source](https://github.com/gridpoint-com/ostara/blob/v0.4.4/lib/ostara/validation.ex#L12-L154)

InstructorLite also has an Ecto-to-JSON-Schema helper, but it consumes an Ecto schema module or a bare Ecto types map rather than an executed changeset. For a types map it marks every property as required and does not inspect `changeset.required`, `changeset.validations`, `changeset.data`, or constraints. Its own documentation says the generated schema is tailored to OpenAI structured outputs and should be treated as a development starting point, not a compatibility-stable general JSON Schema converter. It is therefore not suitable as D20's form contract even though `changeset.types` could technically be passed to it. [InstructorLite JSON Schema documentation](https://hexdocs.pm/instructor_lite/InstructorLite.JSONSchema.html), [InstructorLite types-map source](https://github.com/martosaur/instructor_lite/blob/v1.3.0/lib/instructor_lite/json_schema.ex#L122-L154)

PhoenixSpec analyzes Phoenix routers, JSON view source, `Ecto.Schema` reflection, and source-level `cast/3` calls to generate an OpenAPI 3.1 document at build time. It does not consume a runtime changeset, and its request body inference assumes a conventional controller and schema flow. It is useful for documenting a Phoenix JSON API but does not fit a runtime-selected D20 game launch form. [PhoenixSpec architecture and request inference](https://github.com/dannote/phoenix_spec#how-it-works)

No maintained Hex package was found that takes any already-built `%Ecto.Changeset{}` and produces a complete, portable JSON Schema with equivalent semantics.

### Peri as a shared server schema

Peri avoids reverse engineering a changeset. It defines a data schema first, then exposes both:

- `Peri.to_changeset!/2`, which produces an Ecto schemaless changeset;
- `Peri.to_json_schema/2`, which produces JSON Schema Draft 7.

It maps required fields, enums, string length and pattern rules, numeric ranges, arrays, nested objects, defaults, titles, descriptions, and formats. Dynamic callbacks and conditional Peri types cannot always be expressed statically; the JSON Schema encoder defaults to an unconstrained true schema for unsupported types. D20 must therefore call it with `on_unsupported: :raise` so an unsupported game rule fails during development instead of silently weakening the client schema. [Peri Ecto integration](https://github.com/zoedsoupe/peri/blob/v0.9.1/pages/ecto.md), [Peri JSON Schema guide](https://github.com/zoedsoupe/peri/blob/v0.9.1/pages/json_schema.md)

Peri does not eliminate presentation metadata. Its JSON Schema metadata covers standard annotations such as title, description, default, and format, while SJSF UI Schema remains the correct home for widget and layout choices.

The tradeoff is dependency risk: Peri is active but still on a 0.x release. Its current Hex history and usage are materially stronger than the other schema-first candidates found, but that is not an API-stability guarantee. D20 should pin the accepted minor version, run contract tests against generated changesets and JSON Schemas, and treat schema output changes as public frontend contract changes.

### Gladius as the nested and ordered alternative

Gladius follows the same sound direction as Peri: declare a schema first and derive other representations from it. `Gladius.Ecto.changeset/2` returns a schemaless changeset, while `Gladius.Schema.to_json_schema/2` returns JSON-safe JSON Schema 2020-12. Its list form preserves field declaration order, which is explicitly intended for form rendering. Nested object and list schemas become Ecto embedded changesets, and `Gladius.Ecto.traverse_errors/2` handles their recursive errors. [Gladius ordered schemas and JSON Schema](https://github.com/Xs-and-10s/gladius#ordered-schemas), [Gladius Ecto integration](https://github.com/Xs-and-10s/gladius#ecto-integration)

Those features reduce custom work for nested game configuration. The reason not to prefer it today is maturity rather than design: version 0.6.0 has a small repository history, one listed Hex dependent, and only hundreds of total downloads at the research date. Peri has a much longer release history and substantially wider usage.

Gladius is worth revisiting if D20 needs nested repeatable sections or if Peri's changeset representation makes nested Inertia errors awkward. Its JSON Schema 2020-12 output should still be tested against the selected SJSF validator and every keyword D20 actually emits.

### Schemecto as the Ecto-first alternative

Schemecto is the only project found whose API directly matches the initial idea: take an existing changeset and call `Schemecto.to_json_schema(changeset)`. It can also construct a runtime field list through `Schemecto.new/2`, after which standard Ecto validators can be applied. It supports metadata, enums, arrays, and its own nested `one` and `many` types. [Schemecto README](https://github.com/josevalim/schemecto)

This is less magical than serializing `%Phoenix.HTML.Form{}`: Schemecto reads the standard `types`, `required`, and `validations` fields that already exist on the changeset. It still cannot encode arbitrary custom or cross-field validation functions as JSON Schema, because those functions have no portable representation, and its current fallback silently drops unknown validation metadata.

For D20, Schemecto would require no schema migration for the current Koala and Next Station launch changesets. However, it is not yet a normal versioned dependency. The README installs a moving Git branch, the repository has no releases, and the implementation is small and new. Pinning a commit would make builds reproducible, but D20 would still assume maintenance risk. Use it for the first Ecto-first spike or monitor it until a Hex release, rather than adopting it as the default without contract tests.

### `@sjsf/form` as the Svelte renderer

`@sjsf/form` is an active Svelte 5 library for generating forms from JSON Schema. It is an unofficial Svelte port of the established react-jsonschema-form model. It supports JSON Schema driven dynamic branches through `oneOf`, `anyOf`, dependencies, and `if`/`then`/`else`. [SJSF dynamic forms](https://x0k.dev/svelte-jsonschema-form/guides/dynamic-forms/)

Its separate UI Schema covers the missing presentation layer, including component and widget selection, enum labels, field order, descriptions, help, array controls, and custom Svelte components. [SJSF UI Schema](https://x0k.dev/svelte-jsonschema-form/form/ui-schema/), [SJSF custom components](https://x0k.dev/svelte-jsonschema-form/guides/custom-components/)

SJSF is not tied to SvelteKit. Its generic backend example accepts an `onSubmit` callback, so D20 can call Inertia's router from that callback. SJSF owns the actual `<form>` element and prevents its native submission while it validates and produces a typed object. D20 should not nest that form inside Inertia `<Form>`. [SJSF generic backend](https://x0k.dev/svelte-jsonschema-form/integrations/generic-backend/)

SJSF exposes initial errors and programmatic error updates by field path. A small adapter is still required to translate `inertia-phoenix`'s flat error keys into SJSF paths. That adapter is transport glue, not a form renderer or schema language.

SJSF is also a focused community project rather than an official Svelte package. Before adoption, the spike should verify D20 styling, keyboard and screen-reader behavior, Inertia redirect error handling, boolean payloads, enum atoms and strings, focus-on-error behavior, and bundle impact.

### Why the other Svelte libraries do not fit

Felte manages values, validation, reporting, and submission for developer-rendered HTML. Its own example still writes every `<input>` explicitly. It can handle controls added at runtime, but it is not a JSON Schema renderer. [Felte API](https://api.felte.dev/)

Superforms is designed around SvelteKit server validation, load data, form actions, `use:enhance`, and `ActionResult`. It has an SPA mode for external APIs, but that still requires the SvelteKit package and does not generate controls from the schema. Formsnap is an accessibility-oriented component layer on top of Superforms, so it inherits that mismatch. [Superforms](https://superforms.rocks/), [Superforms SPA mode](https://superforms.rocks/concepts/spa), [Formsnap](https://formsnap.dev/docs)

Svelte Formly does generate controls from configuration, but its current npm release is from 2022 and its published package metadata targets Svelte 3. It is not a reasonable basis for a new Svelte 5 contract. [`svelte-formly` package](https://www.npmjs.com/package/svelte-formly)

TanStack Form for Svelte is also headless state management. It supplies field state, validation, and composition APIs, but the application still chooses and renders every runtime control. Adding it beside Inertia and SJSF would create a third form lifecycle without removing the schema renderer problem. [TanStack Form Svelte documentation](https://tanstack.com/form/latest/docs/framework/svelte/svelte-form)

### Full form engines and cross-framework renderers

JSON Forms has the right separation of JSON Schema, UI Schema, rules, and renderer registry, but its official renderer sets target React, Angular, and Vue. A Svelte integration would require D20 to build the exact renderer registry it is trying not to own. [JSON Forms architecture](https://jsonforms.io/docs/architecture/)

SurveyJS and Form.io already solve more than rendering: they provide their own form or survey schema, conditional behavior, large control catalogs, builders, and submission-oriented platform features. They can be embedded through vanilla JavaScript wrappers, but neither gives D20 a native Svelte component driven directly by an Ecto or Peri schema. Adopting either would require:

- translating the server schema into the engine's proprietary model;
- wrapping its imperative lifecycle in Svelte;
- reconciling its errors and submission state with Inertia;
- accepting a much larger frontend and product surface.

These engines make sense for a no-code form product, questionnaires, or administrator-built workflows. They are disproportionate for a known collection of game launch attributes.

`@json-render/svelte` is a lighter generic runtime UI renderer, but it is not a JSON Schema form implementation. The application defines a component registry and its own UI specification, so it moves the current custom descriptor and renderer behind another abstraction rather than eliminating them. [`json-render` repository](https://github.com/vercel-labs/json-render)

## Recommended transport contract

Do not introduce a D20-specific `fields` language if SJSF is accepted. For new-session forms, send the standardized JSON Schema directly and place the game-defined defaults in its root `default` annotation:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "default": {
    "sheet": "dharug",
    "powers": false
  },
  "properties": {
    "sheet": {
      "type": "string",
      "title": "Sheet",
      "enum": ["dharug", "bruny_island"]
    },
    "powers": {
      "type": "boolean",
      "title": "Use station powers"
    }
  },
  "required": ["sheet", "powers"]
}
```

The endpoint and HTTP method remain page concerns and do not belong in the game schema. SJSF's UI Schema `order` option owns the display sequence instead of relying on JSON object order.

Keep `schema` free of SJSF-specific widget extensions so it remains usable by other JSON Schema tools. Keep widget selection and layout in `uiSchema`.

Only add nested objects, arrays, or conditional branches when a real game requires them. SJSF already renders the relevant JSON Schema structures, so D20 does not need to design its own nested field protocol.

## Submission and validation lifecycle

The direct Ecto-first request lifecycle is:

1. Phoenix asks the game for its existing new-session changeset.
2. The page boundary calls `Schemecto.to_json_schema(changeset)` and adds the declared changeset data as the root schema `default`.
3. The controller sends that schema directly as the Inertia `form` prop.
4. SJSF renders and owns the form controls and client-side JSON Schema validation.
5. SJSF calls `onSubmit` with a typed value.
6. The callback calls `router.post(path, value)` through Inertia.
7. Phoenix calls the same game's existing `changeset(attrs)` and remains authoritative.
8. On failure, the controller calls `assign_errors(changeset)` and redirects back.
9. A small client adapter maps the Inertia errors to SJSF field paths.

The Phoenix adapter explicitly accepts an Ecto changeset in `assign_errors/2`, flattens nested keys such as `team.name` and `items[1].price`, and preserves the errors across the redirect. [inertia-phoenix validation handling](https://github.com/inertiajs/inertia-phoenix#validations)

Do not copy submission errors into JSON Schema or UI Schema. Those schemas describe the controls, while Inertia errors describe one submission attempt.

Client-side attributes such as `required`, `min`, and `maxlength` improve feedback but are never an authorization or data-integrity boundary. The game changeset must always cast and validate the submitted values again.

## Inertia integration choice

With the existing custom renderer, Inertia `<Form>` remains appropriate. With SJSF, use SJSF's form component and Inertia `router.post` from `onSubmit`.

Do not nest SJSF `<Form>` inside Inertia `<Form>` because nested HTML forms are invalid and both libraries intercept submission. Do not add Felte, Superforms, or Inertia `useForm` merely to hold the same form state a second time. One owner should manage field values and client validation, and SJSF already does that job.

Inertia still owns the visit, redirect, page props, progress, and server error callback. SJSF owns runtime rendering, values, JSON Schema validation, and field-level display. The integration code should be limited to submission and error-path translation.

## Current D20 assessment

D20 already implements the first version of the correct architectural idea:

- `PageController.game/2` obtains the game changeset and calls `D20.Form.to_form/1`;
- `D20.Form` turns selected changeset facts into JSON-safe maps;
- `game.svelte` loops over the descriptors and renders enum, boolean, or fallback text controls;
- invalid submissions use `assign_errors(changeset)` and a redirect.

The main issue is not a missing Inertia feature. It is that the current D20 transport contract is too implicit for forms that will grow across games:

- `Attrs` is a map, so field order is not explicit;
- the frontend accepts any `type: string` and treats unknown types as text;
- enum extraction matches Ecto's internal parameterized type shape instead of calling the public enum API;
- common HTML constraints from `input_validations/2` are not projected;
- `errors` exist both in `AttrConfig` and in Inertia form state;
- arrays and nested inputs are advertised by type mapping but do not have complete serialization or rendering semantics;
- labels, widget choices, option labels, groups, and conditional behavior have no explicit owner.

## Recommended next change

Run a focused Schemecto and SJSF spike before changing the common game contract:

1. Pass the existing Koala Rescue Club enum and Next Station London boolean changesets directly to `Schemecto.to_json_schema/1`.
2. Assert the generated types, enum values, required fields, and deliberately unsupported validation behavior in contract tests.
3. Add the declared changeset data as the root schema `default` and pass the schema directly as the `form` prop.
4. Render both games through `@sjsf/form` with its basic theme, overriding controls only when product behavior requires it.
5. Submit the flat typed value through Inertia `router.post` and map `onError` keys to SJSF field paths.
6. Verify redirects, disabled and processing states, error focus, radio and checkbox keyboard behavior, labels, screen-reader relationships, boolean payloads, enum casting, mobile layout, and bundle impact.
7. Add contract tests that assert only the behaviorally relevant JSON Schema, not incidental object ordering.

If that spike passes, replace the bespoke `AttrConfig` DTO and `{#each}` renderer with the self-contained schema and remove `D20.Form`. A private page-boundary helper can add the root default while keeping JSON Schema transport policy out of the game domain.

If the spike fails specifically because Schemecto is too immature or incomplete, test Peri as the schema-first alternative. If that migration is not justified, keep the hand-written changesets and make `D20.Form` emit a strict JSON Schema subset through public Phoenix and Ecto reflection APIs, while still using SJSF to avoid owning the dynamic Svelte renderer.

Do not adopt Ostara, AshPhoenix.Form, OpenApiSpex, Felte, Superforms, Formsnap, or Svelte Formly for this task. Each either changes an unrelated architectural boundary, fails the schemaless changeset requirement, or still leaves D20 responsible for runtime rendering.

## Sources and example search

Primary sources reviewed:

- [Phoenix `to_form/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#to_form/2)
- [Phoenix.HTML.Form](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html)
- [Phoenix.HTML.FormData](https://hexdocs.pm/phoenix_html/Phoenix.HTML.FormData.html)
- [Phoenix HTML input validations](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#input_validations/2)
- [Ecto.Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html)
- [Ecto.Enum](https://hexdocs.pm/ecto/Ecto.Enum.html)
- [Inertia forms](https://inertiajs.com/docs/v3/the-basics/forms)
- [Inertia validation](https://inertiajs.com/docs/v3/the-basics/validation)
- [inertia-phoenix validations](https://github.com/inertiajs/inertia-phoenix#validations)
- [Peri](https://peri.hexdocs.pm/)
- [Peri Ecto integration](https://github.com/zoedsoupe/peri/blob/v0.9.1/pages/ecto.md)
- [Peri JSON Schema conversion](https://github.com/zoedsoupe/peri/blob/v0.9.1/pages/json_schema.md)
- [Gladius](https://github.com/Xs-and-10s/gladius)
- [Gladius Hex package](https://hex.pm/packages/gladius)
- [Schemecto](https://github.com/josevalim/schemecto)
- [Schemecto conversion source](https://github.com/josevalim/schemecto/blob/f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656/lib/schemecto.ex#L198-L358)
- [InstructorLite Ecto JSON Schema helper](https://hexdocs.pm/instructor_lite/InstructorLite.JSONSchema.html)
- [PhoenixSpec](https://github.com/dannote/phoenix_spec)
- [SJSF documentation](https://x0k.dev/svelte-jsonschema-form/)
- [SJSF dynamic forms](https://x0k.dev/svelte-jsonschema-form/guides/dynamic-forms/)
- [SJSF UI Schema](https://x0k.dev/svelte-jsonschema-form/form/ui-schema/)
- [SJSF generic backend integration](https://x0k.dev/svelte-jsonschema-form/integrations/generic-backend/)
- [SJSF validation](https://x0k.dev/svelte-jsonschema-form/guides/validation/)
- [JSON Forms architecture](https://jsonforms.io/docs/architecture/)
- [SurveyJS Form Library](https://surveyjs.io/form-library/documentation/overview)
- [Form.io renderer](https://help.form.io/developers/form-renderer)
- [AshPhoenix.Form](https://ash-phoenix.hexdocs.pm/AshPhoenix.Form.html)
- [OpenApiSpex.Schema](https://hexdocs.pm/open_api_spex/OpenApiSpex.Schema.html)
- [Ostara](https://hexdocs.pm/ostara/readme.html)
- [Felte](https://api.felte.dev/)
- [Superforms](https://superforms.rocks/)
- [Formsnap](https://formsnap.dev/docs)

A search of the official adapters, package documentation, source repositories, and public Elixir examples found the established Ecto and Inertia integration at the error boundary through `assign_errors/2`. It did not find an official Phoenix or Inertia serializer that turns an arbitrary changeset into a complete client UI schema. Peri plus SJSF avoids that reverse conversion by defining a shared schema before the changeset. The remaining UI Schema and Inertia error adapter are unavoidable because validation rules, presentation choices, and transport errors have different responsibilities.
