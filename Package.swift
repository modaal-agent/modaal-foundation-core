// swift-tools-version:5.9

// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import PackageDescription

// Complete concurrency checking as warnings, under the Swift 5 language mode.
//
// The Swift 6 language mode turns the same diagnostics into errors, which means
// adopting it in one commit or not at all. Complete checking reports the whole
// surface at once and lets the count come down release by release, so it is on
// from the first commit rather than added once the code has grown under no
// checking at all. CI does not fail on these warnings; when the count reaches
// zero it starts to.
//
// What a consumer sees is unaffected either way: language mode is a property of
// the package being compiled, not something that propagates through `import`. A
// Swift 6 consumer reads this package's `Sendable` and isolation annotations,
// and those are what this setting exists to get right.
let strictConcurrency: [SwiftSetting] = [
  .enableExperimentalFeature("StrictConcurrency")
]

// Every module carries the package-wide floors below, but a floor is not a
// support claim: ModaalAppServices, ModaalRIBsExtensions and ModaalTheming
// import UIKit and build for iOS only. The watch-consumable products are
// ModaalSupport and ModaalCombine — see README.md, and the watchOS lane in
// .github/workflows/ci.yml that keeps the claim executable.
let package = Package(
  name: "ModaalFoundationCore",
  platforms: [
    .iOS(.v16),
    .watchOS(.v10),
  ],
  products: [
    .library(name: "ModaalSupport", targets: ["ModaalSupport"]),
    .library(name: "ModaalCombine", targets: ["ModaalCombine"]),
    .library(name: "ModaalDiagnostics", targets: ["ModaalDiagnostics"]),
    .library(name: "ModaalTheming", targets: ["ModaalTheming"]),
    .library(name: "ModaalAppServices", targets: ["ModaalAppServices"]),
    .library(name: "ModaalRIBsExtensions", targets: ["ModaalRIBsExtensions"]),
  ],
  dependencies: [
    .package(url: "https://github.com/modaal-agent/CombineRIBs.git", from: "2.2.0"),
    .package(url: "https://github.com/Quick/Nimble.git", from: "14.0.0"),
    .package(url: "https://github.com/Quick/Quick.git", from: "7.6.2"),
  ],
  targets: [
    // MARK: - ModaalSupport

    .target(
      name: "ModaalSupport",
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalSupportTests",
      dependencies: [
        .target(name: "ModaalSupport"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),

    // MARK: - ModaalCombine

    .target(
      name: "ModaalCombine",
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalCombineTests",
      dependencies: [
        .target(name: "ModaalCombine"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),

    // MARK: - ModaalDiagnostics

    .target(
      name: "ModaalDiagnostics",
      dependencies: [
        .product(name: "CombineRIBs", package: "CombineRIBs"),
      ],
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalDiagnosticsTests",
      dependencies: [
        .target(name: "ModaalDiagnostics"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),

    // MARK: - ModaalTheming

    // No dependencies, deliberately: the theming engine is consumable on its
    // own, and adding one here would put it in the graph of every project that
    // only wanted a theme.
    .target(
      name: "ModaalTheming",
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalThemingTests",
      dependencies: [
        .target(name: "ModaalTheming"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),

    // MARK: - ModaalAppServices

    .target(
      name: "ModaalAppServices",
      dependencies: [
        .product(name: "CombineRIBs", package: "CombineRIBs"),
      ],
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalAppServicesTests",
      dependencies: [
        .target(name: "ModaalAppServices"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),

    // MARK: - ModaalRIBsExtensions

    .target(
      name: "ModaalRIBsExtensions",
      dependencies: [
        .target(name: "ModaalSupport"),
        .product(name: "CombineRIBs", package: "CombineRIBs"),
      ],
      swiftSettings: strictConcurrency
    ),
    .testTarget(
      name: "ModaalRIBsExtensionsTests",
      dependencies: [
        .target(name: "ModaalRIBsExtensions"),
        // Imported directly by ModalPresentationSmokeSpec; declared rather than
        // inherited through ModaalRIBsExtensions.
        .target(name: "ModaalSupport"),
        .product(name: "Nimble", package: "Nimble"),
        .product(name: "Quick", package: "Quick"),
      ],
      swiftSettings: strictConcurrency
    ),
  ]
)
