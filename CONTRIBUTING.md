# Contributing

This guide is for contributors to the package itself. If you are consuming it,
start from the [README](README.md).

## 1. This repository is public, and nothing in it names a private consumer

No internal product or repository names, no internal file paths, no
private-specification decision IDs or section numbers, and no instructions for
wiring these modules into one particular downstream project. That covers prose,
code comments, test names, commit messages and any generated artifact.

Write for someone who found this repository on its own: "a consuming project",
not which one. Measurements and findings are welcome — describe them without
naming where they were measured.

The deliberate exceptions are `Modaal.dev` as the copyright holder, which is
what a licence is for, and the `Modaal` module prefix, which is the public API.

**Release notes are not generated from commit messages.** They are the
[CHANGELOG.md](CHANGELOG.md) entry, written by a person. A release page is as
public as a README, and a generated one publishes whatever a commit message
happened to contain.

## 2. Every product stays independently consumable

A consumer names one product and SwiftPM builds its closure and nothing else.
That property is the reason this is one package with six products rather than
one module, and it is easy to lose by accident:

- **`ModaalTheming` has no package dependencies and does not get any.** A
  project that wants a theme engine should not resolve a RIBs framework to get
  one.
- **`ModaalSupport` and `ModaalCombine` import Foundation and Combine only.**
  They are the two products advertised as watch-consumable, and the watchOS job
  in [ci.yml](.github/workflows/ci.yml) builds exactly those two so a UIKit
  import fails CI rather than a consumer's watch target.
- Adding a dependency to any product is a change to what every consumer of it
  resolves. Say in the PR what it buys.

## 3. The module names are the public API

`ModaalSupport`, `ModaalCombine`, `ModaalDiagnostics`, `ModaalTheming`,
`ModaalAppServices`, `ModaalRIBsExtensions`. Renaming one breaks every
consumer's `import` lines and manifest, so it needs the version bump described
under [Releases](#7-releases) and a CHANGELOG entry giving the old and new
names.

The prefix is not decoration. Swift module names are a single flat namespace,
and two modules named `Diagnostics` or `Theming` anywhere in one build graph is
a hard build error — including when the second one is a module the consuming
app wrote itself.

## 4. Platform floors are a published contract

`.iOS(.v16)` and `.watchOS(.v10)`, package-wide. Raising either strands
consumers on the old floor, so it is a breaking release (see
[Releases](#7-releases)) with a CHANGELOG entry that says which product needed
it and why.

A package-level floor is not a per-product support claim: three products import
UIKit and build for iOS only. The claim that is enforceable is the watchOS job,
and it covers `ModaalSupport` and `ModaalCombine`.

## 5. Concurrency: the warning count only goes down

Every target compiles with complete concurrency checking
(`.enableExperimentalFeature("StrictConcurrency")`) under the Swift 5 language
mode. CI does not fail on those warnings today — there are 46 at `0.1.0` — but
new code is expected to add none, and the number in the README is kept current.
When it reaches zero, CI starts gating on it.

Fixing them is not cosmetic. A consumer building in the Swift 6 language mode
sees this package's annotations, not its warnings: an unannotated type is
non-`Sendable` to them, and every isolation crossing is their error to explain.
`Sendable` conformances and `@MainActor` annotations on the public surface are
therefore API, and adding one can be a breaking change for a consumer that
conforms to the protocol.

## 6. Tests

The suites use Quick and Nimble and need a simulator host, so the gate is
`xcodebuild test` rather than `swift test`. Run
[`Scripts/test.sh`](Scripts/test.sh) — it picks an available simulator, and CI
runs the same file, so a green run locally and a green run in CI mean the same
thing:

```sh
Scripts/test.sh

# or against a specific device
TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' Scripts/test.sh
```

Two things that have cost time before:

- **A declared target whose source directory is empty fails the build**, and it
  fails at build-for-testing time rather than where the file was removed. If you
  delete a test target's last source file, delete the target from
  `Package.swift` in the same commit. `ModaalDiagnosticsTests` and
  `ModaalThemingTests` currently hold one placeholder file each for this reason
  — replace it with a real spec rather than removing it and the target.
- **A test that needs a `@testable import` of a second module needs that module
  declared** on the test target. Inheriting it through another target's
  dependency happens to work and is not something to rely on.

## 7. Releases

- Bare semver tags — `0.1.0`, not `v0.1.0`.
- Cutting a release means: write the [CHANGELOG.md](CHANGELOG.md) entry, commit,
  then tag that commit.

**This is a `0.x` line, and a breaking change goes in a minor bump.** The
package is still settling; `0.1.0` → `0.2.0` may rename or remove API, with the
CHANGELOG entry saying what moved. Patch releases (`0.1.1`) stay
source-compatible. Once the shape stops moving, `1.0.0` is cut and the usual
major-for-breaking rule takes over.

**Say so in the README when a breaking minor lands.** SwiftPM does not treat
`0.x` the way some other package managers do: `from: "0.1.0"` resolves to
`0.1.0 ..< 1.0.0`, so a consumer who used `from:` picks up a breaking `0.2.0` on
their next resolve without being asked. The README tells consumers to write
`.upToNextMinor(from:)` instead — keep that instruction accurate, because it is
the only thing standing between them and that resolve.

[modaal-foundation-spritekit](https://github.com/modaal-agent/modaal-foundation-spritekit)
pins this package and tags after it, for the same reason: a breaking release
here strands it until it re-pins, so plan both repositories together.

## 8. Licensing of contributions

MIT, inbound = outbound: submitting a PR means you agree your contribution is
licensed under the [MIT License](LICENSE). There is no CLA.

Third-party code carries its attribution in the file that uses it and an entry
in [NOTICE](NOTICE) — `ModaalTheming` is the standing example. Adding code from
elsewhere means adding both, in the same commit.

## 9. Code style

- Two-space indent; the existing files are the reference.
- Every file starts with `// Copyright (c) 2026 Modaal.dev` and the MIT line.
- Public declarations carry a doc comment saying what the caller gets, not what
  the implementation does.
- Protocols name the capability (`URLOpening`, `HapticFeedbackProviding`), so a
  feature depends on the capability rather than on `UIApplication`. New outbound
  services follow that shape.
- **A name that only distinguishes a type from its siblings by connotation is
  not distinguishing them.** `ModaalAppServices` ships
  `InboundAppServicesWorker` and `OutboundAppServicesWorker` because the pair it
  replaced — `AppServicesWorker` and `AppActionsWorker` — read as
  interchangeable, and readers given only those two names guessed which was
  which at worse than chance. Prefer a word that states the distinction over a
  shorter one that implies it.
- In `ModaalAppServices`, each direction group holds its worker and nothing
  else; every protocol lives in that group's `Protocols/` subdirectory. Adding a
  second type beside a worker means it is either a protocol (move it) or a
  second responsibility (split it).
