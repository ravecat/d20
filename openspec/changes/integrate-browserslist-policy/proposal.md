## Why

The frontend currently has no explicit browser-support contract, so linting cannot reject unsupported platform APIs and the production compiler target is whatever Vite defaults to. A shared Browserslist policy will make the supported threshold inspectable and drive both compatibility linting and the Vite 8 production target.

## What Changes

- Declare the browser policy as `baseline widely available with downstream` with Firefox versions below 128 excluded.
- Add commands that expose the expanded Browserslist set and the compact compiler targets.
- Add `eslint-plugin-compat` to reject unsupported Web APIs and, with its experimental option enabled, unsupported ES APIs during the existing lint command.
- Convert the Browserslist result to compiler targets accepted by Vite 8's Oxc transformer and use them for JavaScript and default CSS build targeting.
- Document `assets/package.json` as the browser-policy source of truth.
- Apply this change only after `migrate-assets-to-vite-8` is implemented and validated.

## Capabilities

### New Capabilities

- `browser-support-policy`: Defines the shared supported-browser query, inspection commands, compatibility linting, and production compiler targeting.

### Modified Capabilities

None.

## Impact

- Depends on the completed `migrate-assets-to-vite-8` change.
- Affects `assets/package.json`, `assets/bun.lock`, `assets/eslint.config.mjs`, `assets/vite.config.mjs`, and `AGENTS.md`.
- Adds direct development dependencies on Browserslist, `eslint-plugin-compat`, and the small Browserslist-to-target adapter.
- Can surface existing API compatibility violations during lint and changes the syntax/CSS lowering threshold of future production builds.
- Does not add runtime polyfills, legacy chunks, CSS source linting, routes, persistence changes, or public session and iframe contract changes.
