// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// Outbound URL-open action — opens a URL in whichever external handler the
/// system picks (Safari for `https://`, a third-party app's universal-link
/// handler, a system scheme like `mailto:`, …). Composition-root-owned and
/// injected into Interactors so the side effect is testable: tests substitute
/// a stub that records the URL handed to `open(_:)`.
///
/// Sibling protocol to `URLHandling`, which sits on the *inbound* side of the
/// app-services boundary (URLs the OS opens *into* the app). `URLOpening` is
/// for app-initiated outbound opens. Interactors MUST depend on `URLOpening`
/// rather than calling `UIApplication.shared.open(_:)` directly — the latter
/// is global state and untestable without device fakes.
///
/// sourcery: CreateMock
public protocol URLOpening: AnyObject {
  /// Asks the system to open `url`. Default implementation
  /// (`OutboundAppServicesWorker.open(_:)`) routes through `UIApplication.shared.open`,
  /// which is main-thread only — the worker hops off-main callers to main
  /// asynchronously.
  func open(_ url: URL)
}
