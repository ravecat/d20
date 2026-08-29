## 1. Page Route Labels

- [x] 1.1 Keep the Home and Account Settings groups under `Pages` with Storybook-safe internal titles and stable story IDs.
- [x] 1.2 Render the route groups as ASCII `/` and `/settings` in the Storybook sidebar.

## 2. Validation and Finalization

- [x] 2.1 Run focused formatting, linting, type checking, visual comparison, and Storybook build validation, then verify the ASCII sidebar labels and story IDs with Chrome DevTools.
- [x] 2.2 Synchronize the verified delta into the authoritative specification, run strict OpenSpec validation, archive the change, and record completion evidence for GitHub issue #257.

## Validation Notes

- Focused Oxfmt and ESLint checks passed for the manager configuration and both page stories.
- TypeScript and Svelte checks passed with zero errors and warnings.
- Desktop, tablet, and mobile visual comparison passed for all four affected story scenarios.
- The static Storybook build passed and retained `home--catalog` plus all `pages-settings--*` IDs.
- Chrome DevTools verified ASCII `/` and `/settings` under `Pages`, their child stories, and a clean console.
- Strict OpenSpec validation passed after synchronizing the authoritative specification.
