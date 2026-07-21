## 1. Inertia CSRF Configuration

- [x] 1.1 Replace the static Inertia visit header with `http.xsrfHeaderName` while preserving the existing LiveSocket CSRF bootstrap.

## 2. Focused Validation

- [x] 2.1 Format and lint `assets/js/app.js` and run the frontend type checker.
- [x] 2.2 Run the frontend test suite and production asset build.

## 3. Broad Validation

- [x] 3.1 Validate the OpenSpec change strictly.
- [x] 3.2 Run the repository-wide `just check` workflow and record any unrelated failures separately.
