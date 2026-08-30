## 1. Shared Page-Story Shell

- [x] 1.1 Add a Storybook page-layout decorator that composes opted-in stories through the production application layout with deterministic Inertia context.
- [x] 1.2 Mark every complete routed page story for the shared layout while preserving component and authentication-dialog story isolation.
- [x] 1.3 Make the production authentication dialog grow intrinsically and move as one surface within a scrollable modal viewport.
- [x] 1.4 Represent `/users/log-in/:token` with distinct Confirmation and Reauthentication story contexts while preserving its stable Storybook ID.
- [x] 1.5 Display Registration Completion as `/users/register/complete`, preserve its stable Storybook ID, and render every route separator as ASCII in the sidebar.
- [x] 1.6 Remove the duplicate standalone Login Methods scenario while retaining distinct sign-in dialog states.
- [x] 1.7 Remove the duplicate standalone Registration Methods scenario while retaining the distinct Confirmation Email Sent state.
- [x] 1.8 Move Magic Link Sent into Home as `Sign In Sent Magic Link` and remove its standalone dialog story.
- [x] 1.9 Move email-backed Reauthentication into Home as `Confirmation With Magic Link`.
- [x] 1.10 Remove Provider Only Reauthentication and the now-empty standalone Sign In authentication-dialog story group.
- [x] 1.11 Move Confirmation Email Sent into Home as `Sign Up With Email` and remove the now-empty Sign Up authentication-dialog group, fixture, and navigation wrapper.

## 2. Regression Coverage

- [x] 2.1 Add focused automated coverage for the page-layout opt-in boundary and shell-owned visible content.
- [x] 2.2 Update reviewed visual references for the full-page stories changed by the application shell.
- [x] 2.3 Update and review Home sign-in and sign-up visual references for the modal scroll-boundary change.
- [x] 2.4 Cover the tokenized confirmation route contexts and update its reviewed visual references.
- [x] 2.5 Cover Registration Completion route metadata without changing its visual-reference identity.
- [x] 2.6 Remove obsolete Login Methods visual references and verify initial sign-in remains covered by Home Sign In.
- [x] 2.7 Remove obsolete Registration Methods visual references and verify initial sign-up remains covered by Home Sign Up.
- [x] 2.8 Replace standalone Magic Link Sent visual references with reviewed Home Sign In Sent Magic Link references.
- [x] 2.9 Replace standalone Reauthentication visual references with reviewed Home Confirmation With Magic Link references.
- [x] 2.10 Remove obsolete Provider Only Reauthentication visual references and update focused catalog coverage.
- [x] 2.11 Replace standalone Confirmation Email Sent visual references with reviewed Home Sign Up With Email references.

## 3. Validation and Delivery

- [x] 3.1 Run focused frontend tests, formatting, lint, type checks, visual comparison, and Storybook build.
- [x] 3.2 Verify Home/Index and the Home authentication stories in the existing Storybook browser page: shell content is visible, the shaded modal layer scrolls while the background remains stationary, and no new console errors appear.
- [x] 3.3 Run strict OpenSpec validation and reconcile the tracking issue with the delivered change.
