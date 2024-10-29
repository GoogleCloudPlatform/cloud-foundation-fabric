# Versioning Scheme Tied to FAST Releases

**authors:** [Ludo](https://github.com/ludoo),  [Julio](https://github.com/jccb), [Simone](https://github.com/sruffilli) \
**date:** Oct 29, 2024

## Status

Proposed

## Context

Our current versioning scheme releases new versions based on changes across all modules. This approach was suitable when modules were the primary focus of development. However, with the increasing importance of FAST, this process no longer aligns with our priorities. We need a versioning scheme that reflects the significance of FAST releases and allows for more frequent updates to modules and documentation. The current release process wasn't designed with FAST in mind, causing friction and delaying releases.

## Proposal

Tie major version releases to FAST releases containing breaking changes or new architectural paradigms. Minor version releases will be used for module updates and documentation changes.

### Development Workflow:

* **Modules and Documentation:** Changes to modules and documentation will be made directly to the `master` branch.
* **FAST Development:** FAST development will occur in a dedicated, protected branch named `fast-dev`. All changes to `fast-dev` must be submitted via Pull Requests..

### FAST Release Process:

1. Merge `master` into `fast-dev`. This ensures that the latest module and documentation changes are included in the FAST release.
1. Merge all pending PRs into `fast-dev`.
1. Create a PR from `fast-dev` to master. This allows for a final review of all changes included in the release and ensures that all tests pass against the release candidate.
1. Merge the PR into master and tag with the new major version number (e.g., v2.0.0, v3.0.0).

## Decision

## Consequences

- **Clearer Versioning:** Version numbers will clearly indicate major FAST releases.
- **Faster Module Updates:** Modules and documentation can be updated more frequently without being tied to the FAST release cycle.
- **Improved FAST Release Process:** The dedicated fast-dev branch and PR process will lead to more stable and predictable FAST releases.
- **Increased Development Velocity:** Decoupling module and FAST development will increase overall development velocity.
- **Potential Learning Curve:** Developers will need to adapt to the new branching and release workflow.

## Implementation:

- Create the protected `fast-dev` branch.
- Update documentation to reflect the new versioning scheme and release process.
- Train developers on the new workflow.
- Implement the new release process for the next FAST release.

As a future improvement we can consider developing a GitHub Action for automated release creation, including tagging, release notes generation, etc.
