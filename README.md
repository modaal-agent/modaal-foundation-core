# modaal-foundation-core

Six small Swift packages for iOS apps: value-type helpers, Combine operators, a
logging seam, a theming engine, an app-services layer over UIKit's scene and
notification callbacks, and modal-presentation helpers for RIBs.

They were written as separate in-tree packages inside a set of iOS app
templates, copied into each template, and drifted. They are one versioned
package here, and each is a product a consumer names on its own.

## Install

```swift
// Package.swift
dependencies: [
  .package(
    url: "https://github.com/modaal-agent/modaal-foundation-core.git",
    .upToNextMinor(from: "0.1.0")),
],
targets: [
  .target(
    name: "MyFeature",
    dependencies: [
      .product(name: "ModaalSupport", package: "modaal-foundation-core"),
      .product(name: "ModaalCombine", package: "modaal-foundation-core"),
    ]
  ),
]
```

SwiftPM builds only the targets in the dependency closure of the products you
name, so taking `ModaalCombine` does not compile — or link — the UIKit modules.

**Use `.upToNextMinor(from:)`, not `from:`, while this is a `0.x` line.** Minor
releases may break API until the package stabilises at `1.0.0`, and SwiftPM does
not treat `0.x` specially: `from: "0.1.0"` means `0.1.0 ..< 1.0.0`, so it would
pick up a breaking `0.2.0` on the next resolve. `.upToNextMinor(from: "0.1.0")`
means `0.1.0 ..< 0.2.0`, and moving to `0.2.0` becomes a deliberate edit against
the CHANGELOG.

## Products

| Product | Depends on | Docs |
| --- | --- | --- |
| `ModaalSupport` | — | [docs/ModaalSupport.md](docs/ModaalSupport.md) |
| `ModaalCombine` | — | [docs/ModaalCombine.md](docs/ModaalCombine.md) |
| `ModaalTheming` | — | [docs/ModaalTheming.md](docs/ModaalTheming.md) |
| `ModaalDiagnostics` | CombineRIBs | [docs/ModaalDiagnostics.md](docs/ModaalDiagnostics.md) |
| `ModaalAppServices` | CombineRIBs | [docs/ModaalAppServices.md](docs/ModaalAppServices.md) |
| `ModaalRIBsExtensions` | CombineRIBs, `ModaalSupport` | [docs/ModaalRIBsExtensions.md](docs/ModaalRIBsExtensions.md) |

**`ModaalSupport`** — `StringCodable`, a pair of protocols for types whose
canonical serialized form is a single string, with `Codable` conformances
derived from them; `AnyActionHandler`, a type-erased callback that holds its
target weakly and can be remapped over its argument type; and a
`LocalizedStringResource` extension that resolves a resource against an
explicit `Locale`. Foundation only.

**`ModaalCombine`** — `Publisher.skip(while:)` and
`CurrentValueSubject.updateValue`, plus a handful of sequence operators:
`compact()` (via an `OptionalType` protocol, so it works on any `Sequence` of
optionals), `flatten()`, `dictionary()` for a sequence of key-value pairs, and
`any(_:)` / `all(_:)`. Foundation and Combine only.

**`ModaalTheming`** — a theme engine for UIKit and SwiftUI: a `Theme` value, an
`Assetable` catalog protocol whose four asset families (color, font, image,
gradient) each resolve through a light/dark `Appearance`, a `ThemeProvider` that
resolves an asset for the current theme and preferred appearance,
`ThemePersistentStorage` for remembering the choice, and the SwiftUI
environment layer — `@Environment(\.theme)`, `ThemeScope`,
`ThemedHostingController`, with the default theme registered by a
`ThemeDefaulting` conformance. Your app supplies the catalog and the default
registration; this package supplies the resolution, the publication and the
persistence. It has no package dependencies, deliberately — see
[docs/ModaalTheming.md](docs/ModaalTheming.md).

**`ModaalDiagnostics`** — one logging seam: `Diagnostics` (log, exception,
user id, custom values) plus a `logs` publisher, and `DiagnosticsWorker`, a
CombineRIBs `Worker` implementing it with settable hooks so a crash reporter or
a test double drops in behind the same protocol.

**`ModaalAppServices`** — the layer between UIKit's app-level callbacks and
feature code, split by direction. `InboundAppServicesWorker` handles what the
system sends the app: it takes URL and remote-notification handler
registrations with a priority, dispatches scene/app callbacks to them in order,
and publishes app-lifecycle transitions. `OutboundAppServicesWorker` handles
what the app asks of the system, as one protocol per capability — opening URLs,
reading and writing the pasteboard, haptics, audio session activation, tracking
and push authorization — so feature code depends on a protocol rather than on
`UIApplication`.

**`ModaalRIBsExtensions`** — modal presentation for CombineRIBs'
`ViewableRouter` with a dismissal token, `NavigationControllable` for
`UINavigationController`, delegate proxies that turn `UIImagePickerController`,
`PHPickerViewController` and `UIAdaptivePresentationControllerDelegate`
callbacks into closures, `NSItemProvider`/`PhotosPickerItem` load publishers,
and `UIView.snapshot()`.

The SpriteKit tier — `ModaalSpriteKitUtils`, `ModaalSpriteKitSupport`,
`ModaalSpriteKitRIBs` — is a separate package,
[modaal-foundation-spritekit](https://github.com/modaal-agent/modaal-foundation-spritekit),
because SwiftPM resolves one package per repository URL.

## Platforms

`.iOS(.v16)` and `.watchOS(.v10)`, declared package-wide.

A package-level floor is not a per-product support claim. `ModaalAppServices`,
`ModaalRIBsExtensions` and `ModaalTheming` import UIKit and build for iOS only.
The **watch-consumable products are `ModaalSupport` and `ModaalCombine`**, and
CI builds exactly those two for a watchOS destination on every push, so the
claim fails visibly if it stops being true.

`ModaalDiagnostics` imports no UIKit but depends on CombineRIBs, whose watchOS
support has not been checked here. It is not advertised as watch-consumable
until someone builds it.

## Concurrency

`swift-tools-version:5.9`, with complete concurrency checking enabled as
warnings on every target (`.enableExperimentalFeature("StrictConcurrency")`).
Language mode does not propagate through `import` — a Swift 6 consumer can use
this package regardless — but annotations do, which is why the checking is on
from the first commit rather than added later.

At `0.1.0` the checking reports **46 warnings**, all in `ModaalAppServices`,
`ModaalRIBsExtensions` and two test targets: UIKit main-actor isolation reached
from synchronous nonisolated code, and non-`Sendable` captures.
`ModaalSupport`, `ModaalCombine`, `ModaalTheming` and `ModaalDiagnostics` are
clean. CI does not fail on these; when the count reaches zero it will.

## Tests

`xcodebuild test` against an iOS Simulator destination — the suites use Quick
and Nimble, which need a simulator host. [`Scripts/test.sh`](Scripts/test.sh)
picks an available simulator and runs them; CI runs the same file.

```sh
Scripts/test.sh

# or against a specific device
TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' Scripts/test.sh
```

51 tests across four suites; `ModaalDiagnosticsTests` and `ModaalThemingTests`
are placeholders that build the module against a `@testable import` and assert
nothing yet.

Quick and Nimble are test-target dependencies. SwiftPM does not resolve a
non-root package's test dependencies, so a project that consumes this package
does not fetch them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release history is in
[CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE). Third-party attributions are in [NOTICE](NOTICE);
`ModaalTheming` is derived from
[SwiftTheming](https://github.com/dscyrescotti/SwiftTheming).
