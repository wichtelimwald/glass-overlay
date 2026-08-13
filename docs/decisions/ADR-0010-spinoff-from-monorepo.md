# ADR-0010: Spin-off from the `wichtelimwald/assistance` mono-repo

**Status:** Accepted
**Date:** 2026-05-20
**Related:** ADR-0012 in `wichtelimwald/assistance` (mono-repo split strategy)

## Context

`GlassOverlay` was previously one module of the `AssistanceKit` umbrella
SwiftPM package in `wichtelimwald/assistance:shared-ui/`. It shared a single
package product with six unrelated modules (CoverFlow, Markdown, Backgrounds,
Buttons, Compatibility, Styles). This coupled the release cadence of
unrelated concerns.

## Decision

Split the `AssistanceKit` umbrella into four standalone SwiftPM packages.
`GlassOverlay` becomes its own repository, `wichtelimwald/glass-overlay`.

Because `GlassOverlay` consumes branded button styles from the `Buttons`
module (which stays in `wichtelimwald/shared-ui`), this package retains
**one** SPM dependency: `https://github.com/wichtelimwald/shared-ui.git`
pinned `upToNextMajorVersion 0.1.0`.

Sibling packages:

- `wichtelimwald/coverflow` (product `CoverFlow`, no deps)
- `wichtelimwald/glass-overlay` (this repo, product `GlassOverlay`, depends on `SharedUI`)
- `wichtelimwald/markdown-ui` (product `MarkdownUI`, no deps)
- `wichtelimwald/shared-ui` (product `SharedUI`: Backgrounds/Buttons/Compatibility/Styles)

## Consequences

**Positive**
- Independent versioning per concern.
- Visible public-API contract at the package boundary.
- Smaller blast radius for breaking changes.

**Negative**
- One external dependency to keep up to date (`SharedUI`).
- Consumers need both `import GlassOverlay` and (when using button styles
  directly) `import SharedUI`.

## Implementation notes

- The migration script (`scripts/migrate-glass-overlay/migrate.sh` in the
  mono-repo) copies `shared-ui/Sources/AssistanceKit/GlassOverlay/` and
  injects `import SharedUI` into `GlassOverlayScaffold.swift`, which
  references the `ActionButton` and `ScaledButtonStyle` types previously
  available implicitly via the umbrella module.
- No Git history is preserved from the mono-repo (clean break).
- Mono-repo cleanup happens in a separate PR after all consumers are on
  the remote SPM dependency.
