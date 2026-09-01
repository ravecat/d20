## Context

Storybook 10 waits for running finite animations before completing an interactive story render. The application header uses five scroll-driven CSS animations with automatic duration; they remain in the `running` state while the scroll timeline is idle, so Storybook reaches its hardcoded five-second fallback before applying the theme decorator. Vitest-driven Storybook tests already pause motion internally, but interactive Storybook does not, and relying on browser `prefers-reduced-motion` leaves behavior dependent on contributor settings.

## Goals / Non-Goals

**Goals:**

- Make Storybook theme changes and story completion independent of production animation timelines.
- Keep visual snapshots and interaction review in deterministic final states.
- Keep the no-motion policy confined to the Storybook preview.

**Non-Goals:**

- Remove or change production animations and transitions.
- Replace dedicated browser tests that validate production motion.
- Add a runtime toolbar control for enabling preview animations.

## Decisions

1. Add a Storybook-only stylesheet imported after the application stylesheet from `.storybook/preview.ts`. This keeps the override out of the production Vite entry and gives its rules an explicit final cascade position.
2. Apply `animation: none`, `transition: none`, and `scroll-behavior: auto` with `!important` to every preview element and pseudo-element. `animation: none` is required because zero duration alone does not reliably terminate scroll-driven animations with automatic duration; immediate scrolling also removes carousel timing from snapshots and interactions.
3. Preserve motion validation in the existing non-Storybook browser tests. A Storybook hook that cancels current animations was rejected because animations can be recreated after render and the interactive completion path waits before after-each cleanup. Browser media emulation was rejected because it would not make the interactive catalog deterministic for every contributor.

## Risks / Trade-offs

- [Storybook cannot demonstrate production motion] - Keep animation behavior covered by dedicated browser tests; introduce an explicitly scoped opt-out only if a future story has an accepted motion-review requirement.
- [Broad important rules can hide a motion-dependent story bug] - Limit the stylesheet to the Storybook preview import and retain production browser coverage for behavior that depends on motion.
- [Future Storybook internals may stop requiring the override] - The stylesheet remains harmless and can be removed after timing verification when Storybook changes its animation-completion handling.
