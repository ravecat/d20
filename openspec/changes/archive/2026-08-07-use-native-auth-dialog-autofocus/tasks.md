## 1. Account Dialog Focus

- [x] 1.1 Mark the first Register and Login email inputs as native autofocus targets.
- [x] 1.2 Keep dialog synchronization limited to opening and closing, remove the extra selectors, and refocus after `tick()` in the shared mode-switch handler.
- [x] 1.3 Replace open-flag synchronization with mount-owned `showModal()` and native-close-owned auth state teardown.
- [x] 1.4 Replace `openPrompt` with an optional-prompt `open` event and update its Header consumer.
- [x] 1.5 Move password visibility into local component state and remove its auth-store event and context field.

## 2. Validation

- [x] 2.1 Verify focused browser coverage for initial dialog focus and both mode-switch focus directions.
- [x] 2.2 Run focused frontend formatting, lint, type-check, browser-test, and strict OpenSpec validation commands.
- [x] 2.3 Re-run focused frontend and strict OpenSpec validation after simplifying focus ownership.
- [x] 2.4 Cover the explicit native close path and re-run focused frontend and strict OpenSpec validation.
- [x] 2.5 Update auth-store coverage for both `open()` forms and re-run focused frontend and strict OpenSpec validation.
- [x] 2.6 Cover local password reveal and mode-switch reset, then re-run focused frontend and strict OpenSpec validation.
