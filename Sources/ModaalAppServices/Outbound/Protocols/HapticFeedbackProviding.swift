// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import SwiftUI
import UIKit

/// Outbound haptic-feedback action — fires `UIImpactFeedbackGenerator` on
/// behalf of the View / Interactor layer. Composition-root-owned and either
/// injected into Interactors via the narrow protocol, OR delivered to the
/// SwiftUI tree via the `\.hapticFeedback` `EnvironmentValue` (haptics often
/// fire from pure SwiftUI Button taps where Interactor injection is
/// overkill).
///
/// Haptics is the ONLY outbound protocol that ships an Environment hop —
/// URL opens, pasteboard reads/writes, and permission prompts all carry
/// domain meaning and route through an Interactor.
///
/// Interactors and Views MUST depend on `HapticFeedbackProviding` rather
/// than calling `UIImpactFeedbackGenerator(style:).impactOccurred()`
/// directly.
///
/// sourcery: CreateMock
public protocol HapticFeedbackProviding: AnyObject {
  /// `UIImpactFeedbackGenerator(style: .light).impactOccurred()` — light tap
  /// accent (e.g. a non-destructive button press).
  func impactLight()
  /// `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` — medium
  /// accent (e.g. a confirming action).
  func impactMedium()
  /// `UIImpactFeedbackGenerator(style: .soft).impactOccurred()` — soft
  /// accent (e.g. an animation landing or a subtle highlight).
  func impactSoft()
}

/// Real-singleton-backed default. Used as the SwiftUI Environment fallback so
/// previews and standalone SwiftUI uses fire real haptics without explicit
/// wiring; the composition root overrides the Environment value with the
/// shared `OutboundAppServicesWorker` instance so test surfaces can substitute a
/// recording stub via `.environment(\.hapticFeedback, …)`.
public final class DefaultHapticFeedback: HapticFeedbackProviding {
  public init() {}

  public func impactLight() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  public func impactMedium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  public func impactSoft() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
  }
}

// MARK: - SwiftUI Environment

private struct HapticFeedbackKey: EnvironmentKey {
  static let defaultValue: HapticFeedbackProviding = DefaultHapticFeedback()
}

public extension EnvironmentValues {
  /// SwiftUI Environment hop for `HapticFeedbackProviding`. Defaults to
  /// `DefaultHapticFeedback` (real `UIImpactFeedbackGenerator`); the
  /// composition root overrides via
  /// `.environment(\.hapticFeedback, outboundAppServicesWorker)` on the rootView so
  /// test surfaces can substitute a recording stub.
  var hapticFeedback: HapticFeedbackProviding {
    get { self[HapticFeedbackKey.self] }
    set { self[HapticFeedbackKey.self] = newValue }
  }
}
