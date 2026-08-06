## Context

The App header receives `authPrompt` as an Inertia shared prop. `D20Web.UserAuth.put_auth_prompt_prop/2` removes the prompt from the session immediately after assigning it to the next page, so the server already owns its one-time lifecycle. The header additionally stores the exact prompt object in `handledPrompt`; because the effect reads and writes that state, the assignment causes one extra effect pass whose only purpose is to match the same reference and return.

`AuthDialog` also converts `reauthenticate` and `mode` into a `$derived` title string before rendering it in the only consumer, the dialog heading. These are presentation branches over component inputs, and keeping localizable strings at the markup consumption site makes their future extraction and review clearer.

## Goals / Non-Goals

**Goals:**

- Remove the redundant client-side prompt reference guard.
- Render all dialog title branches directly in the heading markup.
- Preserve current prompt initialization, visible copy, accessible naming, and dialog behavior.

**Non-Goals:**

- Change the server-side one-time prompt lifecycle or Inertia prop shape.
- Introduce an internationalization library, translation keys, or locale selection.
- Move non-presentation state or multi-use computed values into markup.
- Change account forms, routes, authentication, or dialog layout.

## Decisions

### Trust the server-owned one-time prompt lifecycle

The header effect will return only when `page.props.authPrompt` is nullish. For a prompt value, it will initialize Login mode and open the dialog exactly as before. No local id or object-reference marker will be retained.

Keeping `handledPrompt` was rejected because reference equality is not durable across serialized Inertia responses and duplicates a lifecycle already enforced when the server removes the session value. Replacing it with a payload comparison or generated client id was rejected because there is no second prompt source to deduplicate.

### Branch inside the rendered heading

The dialog heading will use a Svelte `{#if}` block ordered by the existing precedence: reauthentication first, then Register mode, then Login mode. The heading element and `titleId` remain stable, so `aria-labelledby` continues to name the native dialog.

A markup `{#if}` block is preferred over an inline nested ternary because each localizable string remains an independent text node and the three-way precedence is easier to scan. A helper function or `$derived` value was rejected because the title has only one rendering consumer and those alternatives move display copy away from its markup context.

## Risks / Trade-offs

- [A future prompt source republishes the same non-null prop without a server visit] -> Add an explicit prompt id only when that lifecycle exists; object-reference equality would not be a reliable solution.
- [Title precedence changes during the move] -> Preserve the existing reauthentication, Register, Login order and assert all three accessible dialog names in browser coverage.
- [Localization is assumed to be implemented] -> This change only makes copy placement localization-ready; no translation runtime is introduced.

## Migration Plan

1. Remove `handledPrompt` and simplify the effect guard.
2. Remove the derived `title` and render the existing values in the heading branch.
3. Validate all three dialog names, server-prompted Login mode, formatting, lint, and type checking.

Rollback restores the removed state and derived value. No data, deployment, session, or iframe migration is required.

## Open Questions

None.
