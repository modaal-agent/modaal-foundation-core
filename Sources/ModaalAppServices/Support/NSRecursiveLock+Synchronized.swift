// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

extension NSRecursiveLock {
  /// Runs `block` inside `lock()` / `unlock()` and returns its result.
  /// Internal to the module — used by `InboundAppServicesWorker` to guard its
  /// handler arrays.
  func synchronized<U>(_ block: () -> U) -> U {
    lock()
    defer { unlock() }
    return block()
  }
}
