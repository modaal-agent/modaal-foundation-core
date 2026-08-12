// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

public extension Sequence where Element: OptionalType {
  @inlinable
  func compact() -> [Element.Wrapped] {
    return compactMap { $0.flatMap { $0 } }
  }
}

public extension Sequence where Element: Sequence {
  @inlinable
  func flatten() -> [Element.Element] {
    flatMap { $0 }
  }
}
