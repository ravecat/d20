## 1. Responsive Layout

- [x] 1.1 Remove the narrow game detail shell's block-start padding while preserving inline and block-end padding.
- [x] 1.2 Reset the stacked activation panel to intrinsic block sizing while preserving its content padding and the layout gap.

## 2. Browser Coverage

- [x] 2.1 Add a browser-mode game detail test that verifies compact narrow spacing and content-sized activation.
- [x] 2.2 Verify the same browser test preserves the wide preview inset, split panels, and viewport-derived activation minimum.

## 3. Validation

- [x] 3.1 Run the Svelte autofixer and focused game detail unit and browser tests.
- [x] 3.2 Run frontend typecheck, formatting check, and lint.
- [x] 3.3 Recheck the live Koala Rescue Club page at the reproduced mobile viewport and a wide viewport.

## 4. Shared Layout Correction

- [x] 4.1 Remove the game detail shell's block-start padding at all supported widths while retaining inline and block-end padding.
- [x] 4.2 Remove the activation panel's viewport-derived minimum and body flex growth in both stacked and split layouts.
- [x] 4.3 Change the main scroll container's stable scrollbar gutter to reserve both inline edges.

## 5. Expanded Browser Coverage

- [x] 5.1 Update the game detail browser test for content-sized activation and zero preview offset at narrow and wide widths.
- [x] 5.2 Add a layout assertion that the main scroll container reserves scrollbar space on both inline edges.

## 6. Final Validation

- [x] 6.1 Run the Svelte autofixer, focused Chromium and Firefox browser tests, frontend typecheck, formatting check, and lint.
- [x] 6.2 Recheck the live Koala Rescue Club page at narrow and wide viewports.
