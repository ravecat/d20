## 1. Confirm the Vite 8 Prerequisite

- [x] 1.1 Verify every task in `migrate-assets-to-vite-8` is complete and its Vite 8 build, manifest, and frontend checks still pass.
- [x] 1.2 Confirm the worktree contains no unrelated edits before starting the browser-policy dependency and lockfile update.

## 2. Define the Browser Policy

- [x] 2.1 Add the exact Browserslist query, supported-browser and compiler-target inspection scripts, and direct Browserslist, compatibility-linter, and target-converter development dependencies through Bun.
- [x] 2.2 Document `assets/package.json` as the browser-policy source of truth and record the existing Mix and just commands that enforce it.

## 3. Integrate Lint and Build Enforcement

- [x] 3.1 Add the ESLint flat recommended compatibility configuration with Web API and ES API checking enabled.
- [x] 3.2 Run the linter and resolve compatibility findings with compatible code, guarded feature detection, or truthful installed-polyfill declarations without blanket suppression.
- [x] 3.3 Derive Vite 8 `build.target` from the shared Browserslist policy and let the default CSS target inherit the same compact target array.

## 4. Validate the Browser Policy

- [x] 4.1 Run both inspection commands and verify downstream targets are represented and no resolved Firefox version is below 128.
- [x] 4.2 Run frontend formatting, linting, typechecking, tests, production build, and manifest-entry assertions.
- [x] 4.3 Run focused Phoenix page tests, `just check`, the production Docker build, scoped diff checks, and strict validation for both ordered OpenSpec changes.
