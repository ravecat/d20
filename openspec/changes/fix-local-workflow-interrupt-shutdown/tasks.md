## 1. Restore the Sequential Baseline

- [x] 1.1 Make public `serve` route exact-node reuse to a watched configuration touch and missing-node startup to the private `start` setup and Watchexec helper.
- [x] 1.2 Restore `up` as Docker Compose followed by `serve`, without Concurrently, Storybook, or a Bash signal wrapper.
- [x] 1.3 Add a dedicated `storybook` recipe that forwards optional arguments to the atomic frontend Storybook command.
- [x] 1.4 Remove Concurrently from the Nix development shell after eliminating its final command consumer.
- [x] 1.5 Keep dependency installation and migrations explicit instead of expanding the runtime watch roots.

## 2. Contributor Contract

- [x] 2.1 Document the separate application and Storybook commands, retained detached Compose services, and the absence of combined foreground supervision.
- [x] 2.2 Document explicit dependency installation, migration execution, and the subsequent `serve` restart boundary.

## 3. Validation

- [x] 3.1 Validate Just parsing, public command discovery, exact and missing EPMD routing, custom node arguments, Storybook argument forwarding, and Docker-before-serve command order.
- [ ] 3.2 Exercise the real sequential `just up` workflow and characterize its documented interactive shutdown without leaving invocation-owned processes.
- [x] 3.3 Run strict validation for the change and all repository OpenSpec artifacts.
