## Context

Account Settings currently owns `GET` and `PUT /users/settings`, email confirmation below `/users/settings/confirm-email/:token`, and five provider-link start routes below `/users/settings/auth/*`. Controllers, shared navigation, form actions, authentication return destinations, an Apple result cookie, frontend fixtures, and tests all embed that family. Storybook separately labels the same page `/settings` while rendering its Inertia context at `/users/settings`.

GitHub issue #260 and its prior local Storybook commits have not been published remotely. The approved change intentionally replaces rather than aliases the existing route family.

## Goals / Non-Goals

**Goals:**

- Make `/profile` the only Account Settings page and update action route.
- Keep email confirmation and every provider-link start route under the same `/profile` family.
- Align generated links, redirects, stored return destinations, cookie scope, tests, specifications, and Storybook with that family.
- Preserve controller modules, page components, account behavior, provider security semantics, explicit Storybook component ID, and child story identities.

**Non-Goals:**

- Preserving or redirecting `/users/settings*` URLs.
- Renaming `UserSettingsController`, `AccountSettingsPage`, internal account concepts, or visible Account Settings copy.
- Changing provider callbacks, authentication rules, persistence, schemas, or game/session contracts.

## Decisions

### Replace the complete route family atomically

The Phoenix router will expose only `GET /profile`, `PUT /profile`, `GET /profile/confirm-email/:token`, and `GET /profile/auth/:provider` for the existing supported providers. Every generated path and hard-coded browser destination changes in the same commit.

Keeping aliases was rejected because the user explicitly requested no backward compatibility and dual route families would make tests, security review, and canonical navigation ambiguous.

### Keep the existing controllers and domain vocabulary

The route rename does not rename controllers, Svelte modules, form fields, or Account Settings copy. `/profile` is a navigation identity, not a new account domain or duplicate page.

Renaming implementation modules was rejected as unrelated churn with no route-level benefit.

### Move nested flows under `/profile`

Provider-link starts and email confirmation remain descendants of the page that initiates them. Controller redirects, provider result handling, safe return destinations, and the Apple link-result cookie path all target the new family.

Leaving nested routes under `/users/settings` was rejected because it would preserve the obsolete public prefix and split one user journey across two route families.

### Preserve Storybook IDs while changing its route identity

The Account Settings metadata title changes to `Pages/Authenticated/∕profile`, and its layout decorator uses `/profile`. The explicit `pages-settings` component ID and authored child exports remain unchanged so existing direct Storybook story IDs and visual ownership remain stable.

Changing the ID to `pages-profile` was rejected because the requested change concerns the route label, and the repository specification requires identity preservation.

## Risks / Trade-offs

- [Previously issued email-confirmation links use the removed path] -> This is an accepted breaking change; no compatibility route is added. Focused tests prove only the new path is routable.
- [In-flight authentication sessions may hold `/users/settings` as a return destination] -> This is an accepted consequence of the atomic route replacement. New application requests and provider flows store only `/profile`.
- [Apple link-result cookies scoped to the old path are not sent to `/profile`] -> Change the cookie scope together with producer and consumer routes; old one-use result cookies expire naturally.
- [Broad literal replacement could alter archived historical records] -> Update executable code, tests, main specs, and affected active changes only. Leave archived OpenSpec history unchanged.
- [Storybook hierarchy change can create new IDs implicitly] -> Retain the explicit `pages-settings` ID and validate exact metadata plus visual baselines.

## Migration Plan

1. Update main and affected active OpenSpec requirements so `/profile` is authoritative.
2. Replace router declarations and all runtime-generated Account Settings destinations atomically.
3. Update frontend actions, links, fixtures, tests, Storybook metadata, and visual references.
4. Verify `mix phx.routes` contains the new family and no `/users/settings*` route.
5. Run focused backend, frontend, Storybook, and strict OpenSpec validation before integration.
6. Roll back only by reverting the complete commit so routes, generated links, cookie scope, and tests return together.

## Open Questions

None.
