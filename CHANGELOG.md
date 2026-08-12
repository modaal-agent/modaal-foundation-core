# Changelog

## [0.1.0] — 2026-08-12

First public release. Six products, previously six separate in-tree packages
copied into each of a set of iOS app templates.

**This is a `0.x` line.** Minor releases may break API while the package
stabilises. Pin with `.upToNextMinor(from:)` rather than `from:` — SwiftPM's
`from: "0.1.0"` means `0.1.0 ..< 1.0.0`, which would accept a breaking `0.2.0`
without asking.

### Added

- **`ModaalSupport`** — `StringCodable`, `AnyActionHandler`, and a
  `LocalizedStringResource` extension that resolves against an explicit
  `Locale`.
- **`ModaalCombine`** — `Publisher.skip(while:)`,
  `CurrentValueSubject.updateValue`, `compact()`, `flatten()`, `dictionary()`,
  `any(_:)` and `all(_:)`.
- **`ModaalTheming`** — the theme engine: `Theme`, the `Assetable` catalog
  protocol over four asset families, `ThemeProvider`, `ThemePersistentStorage`.
- **`ModaalDiagnostics`** — the `Diagnostics` protocol and `DiagnosticsWorker`,
  with settable hooks for a crash reporter or a test double.
- **`ModaalAppServices`** — `InboundAppServicesWorker` for prioritized URL and
  remote-notification dispatch plus the app-lifecycle publisher, and
  `OutboundAppServicesWorker` implementing one protocol per outbound capability.
- **`ModaalRIBsExtensions`** — modal presentation for `ViewableRouter`,
  `NavigationControllable`, picker delegate proxies, load publishers for
  `NSItemProvider` and `PhotosPickerItem`, `UIView.snapshot()`.
- CI: `xcodebuild test` on an iOS Simulator destination, plus a watchOS build of
  `ModaalSupport` and `ModaalCombine` that makes the watch-consumable claim
  executable.

### Changed from the in-tree packages

These matter to anyone moving from a copy of the originals.

- **Every module took a `Modaal` prefix.** `SharedUtility` → `ModaalSupport`,
  `CombineExtensions` → `ModaalCombine`, `Diagnostics` → `ModaalDiagnostics`,
  `SimpleTheming` → `ModaalTheming`, `AppServices` → `ModaalAppServices`,
  `RIBsExtensions` → `ModaalRIBsExtensions`. Swift module names are one flat
  namespace, and the likeliest collision is a consuming app's own `Diagnostics`
  or `Theming` module. A rename rewrites every consumer's `import` lines, so it
  happened before the first public tag rather than after.
- **The two `ModaalAppServices` workers are named by direction.**
  `AppServicesWorker` → `InboundAppServicesWorker`, `AppActionsWorker` →
  `OutboundAppServicesWorker`, and the composite protocols follow
  (`AppServicesWorking` → `InboundAppServicesWorking`, `AppActionsWorking` →
  `OutboundAppServicesWorking`). The old pair could not be told apart from the
  names: in a blind test, readers given only the two names split on which one
  received incoming URLs and which one opened them, and the majority guessed
  backwards. The narrow per-capability protocols (`URLOpening`,
  `AppServicesRegistering`, …) are unchanged.
- **`AppLifecycleObserving` moved to the inbound worker.** It was on the
  outbound composite, where it was the one member the app did not initiate.
  Construct `InboundAppServicesWorker(notificationCenter:)` rather than the
  outbound worker to drive it from a test; the outbound worker no longer takes a
  `NotificationCenter`. The protocol itself is unchanged.
- **The iOS floor is `.v16` package-wide.** `CombineExtensions` and
  `Diagnostics` declared `.iOS(.v15)` in-tree. Nothing consumed them at 15 at
  the time of the move; a project that still needs 15 cannot use this package.
- **`ModaalSupport` declares no build-tool plugins.** The original declared
  SwiftGen and xcstrings-tool, an empty `resources: []`, and a `swiftgen.yml`
  containing only an output directory. The package has no asset catalog, no
  string catalog, and no source referencing a generated symbol, so all of it was
  removed. Consumers with catalogs of their own declare the plugins on their own
  targets, where the catalogs are.
- **CombineRIBs is pinned `from: "2.2.0"` everywhere.** `AppServices` had been
  left on `2.1.0` while its siblings moved.
- **Complete concurrency checking is on for every target**, as warnings under
  the Swift 5 language mode. 46 at this release, all in `ModaalAppServices`,
  `ModaalRIBsExtensions` and two test targets. CI does not gate on them yet.
- **`Theme` is `Sendable` and `ThemeProviding` is `AnyObject`-constrained.**
  Both landed in the originals shortly before the move, so a copy older than
  that differs. They are source-compatible for callers and are what a consumer
  compiling in the Swift 6 language mode needs.
- Test files moved from `Sources/<Module>Tests/` to `Tests/<Module>Tests/`, and
  test bundles follow their targets: `ModaalSupportTests`, and so on.
