## 1. App UI Ownership

- [x] 1.1 Relocate the current global header and footer components into `assets/js/app/ui` without changing their markup, styles, or runtime behavior.
- [x] 1.2 Add the App UI segment public API, update the layout and header dependency imports, keep the compatible mode type local, and remove the obsolete Shared header and footer exports.
- [x] 1.3 Relocate the header browser test to the mirrored App UI test path and update its import and ownership description.

## 2. Validation

- [x] 2.1 Run the focused App layout unit and browser tests plus the relocated header browser test.
- [x] 2.2 Run frontend formatting checks, lint, type checking, and the complete frontend test suite.
- [x] 2.3 Validate the completed OpenSpec change in strict non-interactive mode.
