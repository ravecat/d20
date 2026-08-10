## 1. Vite Development Dependency Discovery

- [x] 1.1 Replace the direct SJSF radio component import with the package registration entry and theme lookup, then remove the application-maintained optimizer include list.

## 2. Validation

- [x] 2.1 Run a forced cold Vite dependency scan and confirm it starts without the SJSF package-subpath error.
- [x] 2.2 Run the focused launch-form tests, frontend type checking, and frontend linting.
- [x] 2.3 Build production assets and run strict OpenSpec validation.
