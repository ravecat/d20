## 1. Account Settings Provider Surface

- [x] 1.1 Replace the fixed provider rows with one derived available-provider list that reuses the trusted provider icons, omits unavailable providers and the empty section, and renders either a provider-specific Link action or Linked text.
- [x] 1.2 Expand Account Settings into a compact responsive grid that keeps provider items and account forms readable and keyboard operable from narrow mobile through wide desktop viewports.
- [x] 1.3 Remove the page-local maximum width and stretch account cards that share a responsive grid row to equal block sizes while preserving the single-column mobile flow.
- [x] 1.4 Center provider identity and equal state slots and apply one compact block size to provider link actions, form inputs, and submit buttons.
- [x] 1.5 Match the complete provider-row block size to the shared compact input and submit height and present `Link` as accent text without button styling.
- [x] 1.6 Remove the established-username claim that it cannot be changed while preserving the current username display and claim-operation behavior.
- [x] 1.7 Split each provider item into a neutral identity block and a separate same-height state control, rendering a distinct `Link` anchor before linking and a muted non-interactive `Linked` control afterward.
- [x] 1.8 Bound provider items between 13 rem and 20 rem, distribute available row space within those limits, and wrap additional providers only when another minimum-width item no longer fits.
- [x] 1.9 Keep every provider on a separate row through the existing 34 rem mobile breakpoint, then restore minimum-width wrapping above it.
- [x] 1.10 Replace independent flex-line sizing with shared auto-fitting grid tracks so partial final rows align with preceding columns while preserving the 13 rem to 20 rem bounds.

## 2. Coverage and Catalog

- [x] 2.1 Update focused Account Settings component tests for available linked and unlinked providers, unavailable-provider omission, and the all-unavailable section state.
- [x] 2.2 Update Account Settings Storybook scenarios so mixed availability and the all-unavailable boundary remain deterministic and inspectable.
- [x] 2.3 Cover the established-username supporting copy in the focused Account Settings component test.

## 3. Validation and Completion

- [x] 3.1 Run focused frontend formatting, component tests, linting, and type checks for the changed surface.
- [x] 3.2 Inspect the production story in the configured browser at representative wide desktop and narrow mobile viewports, confirming compact reflow, provider visibility, control alignment and sizing, equal-height desktop cards, focus affordances, and no horizontal overflow.
- [x] 3.3 Run strict OpenSpec validation, synchronize the completed delta specifications, and archive the change.
- [x] 3.4 Run focused frontend formatting, component tests, linting, and type checks for the provider-row correction.
- [x] 3.5 Inspect linked and unlinked provider rows in Storybook at desktop and mobile sizes, confirming row, input, and submit heights match, text-link styling remains clear, focus is visible, and no horizontal overflow occurs.
- [x] 3.6 Re-synchronize the corrected delta specification, run strict OpenSpec validation, and archive the change.
- [x] 3.7 Run focused frontend formatting, linting, component tests, and type checks for the state-alignment correction.
- [x] 3.8 Inspect linked and unlinked provider states in Storybook at desktop and mobile sizes, confirming separate identity and state blocks, unambiguous click affordance, equal control heights, visible focus, and no horizontal overflow.
- [x] 3.9 Re-synchronize the corrected delta specification, run strict OpenSpec validation, and archive the change.
- [x] 3.10 Run focused frontend formatting, linting, component tests, and type checks for the provider width correction.
- [x] 3.11 Inspect two-, three-, and simulated four-provider layouts in Storybook across narrow, intermediate, and wide viewports, confirming 13 rem minimum behavior, the 20 rem cap, correct wrapping, and no horizontal overflow.
- [x] 3.12 Re-run focused validation, inspect the provider layout at and immediately above the 34 rem mobile breakpoint, re-synchronize the updated delta specification, run strict OpenSpec validation, and archive the change.
- [x] 3.13 Run focused frontend validation and inspect one-, two-, three-, and simulated four-provider layouts at mobile, wrapped, and wide sizes, confirming shared column widths, bounds, wrapping, and no horizontal overflow.
- [x] 3.14 Re-synchronize the corrected provider-layout requirement, run strict OpenSpec validation, and archive the change.
