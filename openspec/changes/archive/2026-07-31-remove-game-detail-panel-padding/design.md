## Context

The game detail shell already owns responsive page insets, and `.game-detail-layout` owns the `1rem` separation between activation and description. Inside the two layout columns, `.game-detail-activation` and `.game-detail-description-panel` each add another `1rem` of padding. The resulting nested inset is visible at both stacked and split breakpoints.

The activation column already uses flex and grid gaps for spacing among metadata, fields, action, feedback, and errors. The description is a single prose region whose column placement is already established by the parent grid.

## Goals / Non-Goals

**Goals:**

- Remove internal padding from the activation and description panels.
- Keep sibling separation owned by the parent grid gap.
- Keep activation internal separation owned by existing flex and grid gaps.
- Preserve responsive shell insets, description overflow, and activation behavior.
- Verify the resulting geometry in real browsers at narrow and wide widths.

**Non-Goals:**

- Changing the preview, grid column proportions, layout gap, or shell padding.
- Changing form controls, metadata labels, description typography, or panel colors.
- Changing routes, session creation, Inertia props, or embedded game behavior.

## Decisions

1. Remove the two panel padding declarations without adding compensating margins.

   The parent grid and existing internal flex and grid containers already define each required relationship. Adding replacement margins would keep multiple spacing owners and recreate the same compounding problem.

2. Preserve panel elements and overflow behavior.

   The semantic `aside` and `section`, their accessible names, backgrounds, border radii, and the description's bounded overflow remain unchanged. Only their internal insets change.

3. Extend the existing browser geometry test.

   At narrow and wide viewports, the test will verify that the activation's final action reaches the panel block end and that description text begins at the panel inline and block start. Existing assertions continue to cover the parent layout gap, split placement, and description overflow.

## Risks / Trade-offs

- [Panel backgrounds no longer create a visible frame around their content] - Mitigation: the current backgrounds are intentionally subtle, and the requested composition treats these elements as layout columns rather than padded cards.
- [Scrollbars can sit closer to description text] - Mitigation: the description keeps its stable gutter, so scrollbar space remains reserved independently of panel padding.
- [Future panel children may need their own local inset] - Mitigation: add spacing to the nearest relationship-owning child container instead of restoring blanket panel padding.
