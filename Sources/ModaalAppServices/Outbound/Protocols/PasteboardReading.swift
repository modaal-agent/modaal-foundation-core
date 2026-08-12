// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// App-initiated read of the system pasteboard. Lives next to the other
/// outbound singleton wrappers because it's an app-initiated *pull* from a
/// system singleton (`UIPasteboard.general`) — same code path and ownership
/// as the outbound calls, even though the data flows inward.
///
/// Composition-root-owned and injected into Interactors so the
/// `UIPasteboard.general.string` access is testable: tests substitute a stub
/// that returns a scripted value. Interactors MUST depend on this protocol
/// rather than calling `UIPasteboard.general.string` directly.
///
/// sourcery: CreateMock
public protocol PasteboardReading: AnyObject {
  /// Reads the current pasteboard string. Returns `nil` when the pasteboard
  /// is empty or holds a non-string payload.
  func readString() -> String?
}
