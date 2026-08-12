// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// Outbound pasteboard-write seam — sibling to `PasteboardReading` (the
/// app-initiated read). Composition-root-owned and injected into Interactors
/// that need to write to the system pasteboard so the
/// `UIPasteboard.general.string = …` side effect is testable: tests
/// substitute a stub that records the call. Interactors MUST depend on this
/// protocol rather than writing to `UIPasteboard.general.string` directly.
///
/// sourcery: CreateMock
public protocol PasteboardWriting: AnyObject {
  /// Writes `value` to `UIPasteboard.general.string`. The default
  /// implementation (`OutboundAppServicesWorker.writeString(_:)`) performs the
  /// assignment synchronously on whatever thread the caller is on; the system
  /// pasteboard tolerates writes from any thread.
  func writeString(_ value: String)
}
