## Context

The centering implementation is already delivered locally in commit `64f6e824` on `master` and this registered worktree. Its CSS animations combine a stepped whole-sequence transform with a one-slide interpolation; the current 5-second dwell and 0.6-second transition still feel abrupt. Canonical links precede inert copies, and focus temporarily clears displacement. The user authorized extending issue #272 and amending this same local commit with softer motion. The separate `split-home-carousel-lanes` change in `work3` does not own this delivery and remains outside this scope.

## Goals / Non-Goals

**Goals:** Center the second card at the initial settled position and each succeeding middle card after advancement in both compact rows, with symmetric clipped neighbors. Give all moving home rows a 5-second stationary dwell and a 1.1-second ease-in-out transition. Preserve supported widths, two-item looping, reduced motion, and canonical keyboard access.

**Non-Goals:** Change hero or singleton geometry, server ordering, lane membership, controls, or backend contracts; introduce JavaScript carousel state.

## Decisions

- Position each multi-item compact track relatively with an inline offset equivalent to `calc(50cqw - 1.5 * var(--slide-basis) - var(--slide-gap))`. The existing container width, card basis, and gap determine the second card's center. A fixed pixel offset would fail as the container resizes; changing `transform` or `translate` for centering would interfere with their animation roles.
- Append the first entry as one additional inert visual copy after each doubled multi-item sequence. The track has `2n + 1` slides, so derive whole-loop displacement as `-100% * n / (2n + 1)` and interpolation as `-100% / (2n + 1)`. These fractions retain the rendered slide width, including fractional layout rounding. Physical-track `-50%` no longer represents the logical loop length after appending the tail. The extra copy prevents a two-item track from exposing blank space after its negative centering offset. Singletons remain unduplicated.
- Clear the compact alignment offset during the existing group focus override, together with animated displacement, so native focus scrolling can reveal the first canonical link. Restore it when focus leaves. Reduced motion retains the centered static composition when the group is unfocused.
- Change the shared cycle to `6.1s` and the stationary keyframe endpoint to `81.967213%` (`5 / 6.1 * 100`). Apply `ease-in-out` to the one-slide interpolation while retaining the stepped whole-sequence clock. Both clocks must share the same cycle so their reset and advancement coincide, and all three moving home rows receive the same cadence. The existing geometry and loop fractions remain unchanged.
- Retain native CSS transform and translate animations. A new carousel library or JavaScript animation state would add complexity without helping this timing-only adjustment.
- Use existing home unit/browser tests and static presentation checks. Do not add animation-object queries, playback manipulation, timing assertions, or geometry assertions to tests. Screenshot defaults suppress motion, so baselines are expected to remain unchanged. Validate natural movement, hover pause, focus recovery, and retained centering on the actual `http://localhost:5000/` page after `master` serves the integrated change, without temporary CSS substitution or restarting the user's server.

### Motion reference

Reviewed on 2026-09-09: the [Apple home page](https://www.apple.com/) loads its [Endless entertainment gallery script](https://www.apple.com/v/home/a/built/scripts/endless-entertainment-gallery.built.js). The normal slide curve is `cubic-bezier(0.645, 0.045, 0.355, 1)`, and the initialized slide duration is 1 second. The markup's `4.16` autoplay value and the script's duration adjustment imply a 5-second start-to-start cycle, approximately 4 seconds stationary plus 1 second moving. These are source-derived values, not frame measurements or a promise that every Apple gallery uses identical timing. Our 5-second dwell and 1.1-second `ease-in-out` transition deliberately retain a longer reading interval and soften acceleration and deceleration without copying Apple's implementation.

[web.dev's animation performance guidance](https://web.dev/articles/animations-and-performance) recommends transform-based motion because animating geometry can trigger layout and painting. The existing CSS track mechanism already fits that guidance; changing its timing is sufficient.

## Risks / Trade-offs

- Negative alignment can exhaust a short track near wrap - retain sufficient inert tail coverage for two-game collections and verify them visually.
- The first canonical card begins partly clipped - clear alignment on focus and verify keyboard order and visible focus.
- Screenshot defaults suppress motion and do not prove continuous playback - observe the actual integrated page in DevTools while tests cover static presentation and accessibility.
- Increasing the transition duration without changing the hold percentage would shorten the intended dwell or desynchronize the stepped and interpolated tracks - update the shared cycle and hold percentage together.

## Migration Plan

No migration is required. After focused checks, integrate a temporary local commit into `master` for actual served-page validation. Once that passes, synchronize the delta, archive this reactivated change through the native OpenSpec lifecycle, and fold the follow-up into the existing centering commit as explicitly requested. Preserve active user processes. Revert the scoped component, test expectation, and screenshot changes to roll back the combined delivery; restoring the old timing values alone rolls back this follow-up.

## Open Questions

None. Centering applies to settled, unfocused compact rows. The approved softer cadence applies equally to Playable, the Games hero, and the lower Games row; keyboard focus and reduced motion retain their existing behavior.
