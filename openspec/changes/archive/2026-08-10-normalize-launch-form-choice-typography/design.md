## Context

The shared SJSF stylesheet imports the basic theme and then adapts generated controls to the D20 shell. Text inputs declare their own size, but radio and checkbox labels do not, so those choice rows inherit the responsive root size instead of the `0.875rem` regular-copy size already used by the game description. The result is visible on launch forms with enum or boolean fields.

## Goals / Non-Goals

**Goals:**

- Make radio and checkbox choice labels match regular game-description text sizing.
- Apply the correction at the shared generated-form boundary so every launch schema receives the same treatment.
- Verify the computed typography in a real browser while retaining semantic queries.

**Non-Goals:**

- Redesign form spacing, control geometry, labels, submit actions, or game-detail typography.
- Change SJSF rendering, schemas, submitted values, or server-side validation.
- Introduce a new global typography token or dependency.

## Decisions

### Set the size on shared choice-row selectors

Add `font-size: 0.875rem` to the existing `.sjsf-checkbox`, `.sjsf-checkboxes`, and `.sjsf-radio` rule. These selectors represent all visible SJSF choice labels already styled as one family, and `rem` preserves user root-size preferences.

Alternative: change the application root size or the game description size. Rejected because both have broader layout consequences and do not express the choice-control contract.

Alternative: add a new global typography custom property. Rejected because the current stylesheet uses local typography literals and this single correction does not justify a new public or theme-level token.

### Compare computed styles in the existing browser suite

Extend the game-detail browser fixture with a boolean choice and compare both radio and checkbox label font sizes with the visible description paragraph. Existing role-based lookup and native label association provide stable access without production test hooks.

Alternative: assert the CSS source text or a styling class in a simulated DOM test. Rejected because that would not verify the imported-theme cascade or the browser-computed result.

## Risks / Trade-offs

- [Long choice labels occupy slightly less vertical text space] -> Existing wrapping and minimum interaction height remain unchanged, and the browser suite retains the row geometry assertions.
- [A future regular-copy size change could leave both literals out of sync] -> The computed-style regression test makes the intended relationship explicit and will fail until both surfaces are reconciled.

## Migration Plan

Deploy as a stylesheet-only client update with no data or runtime migration. Roll back by reverting the choice-row font-size declaration and its regression assertions.

## Open Questions

None.
