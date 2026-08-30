## Context

Storybook currently displays every routed page directly under `Pages`. Home and `/users/log-in/:token` each contain both anonymous and authenticated scenarios in one CSF metadata object, while `/settings` is authenticated-only and `/users/register/complete` is public-only. Because a CSF metadata title applies to every exported story, mixed files cannot place individual scenarios under different sidebar branches.

The existing page decorator already derives the production shell's Inertia authentication context from each story's args. Explicit Storybook IDs preserve established public story links independently from file paths and visible titles. Visual baselines, however, follow story source paths and must move with split files.

## Goals / Non-Goals

**Goals:**

- Make the public and authenticated application surfaces explicit in Storybook navigation.
- Ensure each complete page metadata object contains scenarios for exactly one authentication boundary.
- Keep production components, route labels, deterministic data, and application-shell behavior unchanged.
- Preserve established public story IDs and assign explicit non-conflicting IDs to newly separated authenticated groups.

**Non-Goals:**

- Change production authentication, authorization, routes, page layout, or page components.
- Duplicate shared components or widgets under both access branches.
- Add new page states beyond reorganizing the existing catalog.

## Decisions

### 1. Scope the hierarchy to complete pages

Complete routed stories will live under `assets/stories/pages/public/` or `assets/stories/pages/authenticated/` and use explicit titles beginning with `Pages/Public` or `Pages/Authenticated`. Shared and widget stories remain in their existing top-level locations.

Using only global `signed` and `unsigned` directories was rejected because authentication is not a meaningful organizing boundary for every component. `Public` and `Authenticated` are used because they describe application access surfaces and avoid confusing registration with current session state.

### 2. Split mixed metadata instead of encoding access in story names

Home's anonymous catalog and authentication-entry scenarios remain in the public Home file, while `Confirmation With Magic Link` moves to an authenticated Home file. Signed-out confirmation remains in the public tokenized-route file, while Reauthentication moves to an authenticated tokenized-route file. Account Settings moves intact to authenticated pages, and Registration Completion moves intact to public pages.

Prefixing story names with `Public` or `Authenticated` inside the existing files was rejected because the sidebar would still present impossible states under one page group. Duplicating all Home stories in both groups was rejected because it would create redundant scenarios and visual baselines.

### 3. Preserve public identities and make authenticated identities explicit

The public Home and tokenized confirmation groups retain their established metadata IDs because they contain the existing primary public scenarios. Account Settings and Registration Completion also retain their established IDs. Newly separated authenticated Home and tokenized confirmation groups receive new explicit IDs so Storybook has no duplicate component identifiers.

Preserving every old story URL is impossible when one metadata group becomes two because Storybook derives every story ID from one component-level metadata ID. Keeping the public IDs minimizes link churn across the larger public scenario sets.

### 4. Move visual references with their story sources

Reviewed screenshots will be moved to paths matching the new story source layout. Mixed baseline directories will be split so each scenario follows its owning public or authenticated story file. The rendered pixels are expected to remain unchanged; normal visual comparison will confirm that the reorganization did not alter presentation.

## Risks / Trade-offs

- [The two moved authenticated scenarios receive new Storybook URLs] -> Use explicit stable IDs for the new groups and preserve all public and single-surface group IDs.
- [Physical story moves can orphan screenshot references] -> Move each viewport baseline with its owning source and run the complete visual matrix.
- [Story args and shell authentication context could diverge after splitting] -> Give each metadata object one fixed authentication boundary and keep focused decorator tests for every routed group.
