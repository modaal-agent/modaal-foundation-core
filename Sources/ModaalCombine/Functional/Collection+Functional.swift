// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

public extension Collection {
  /// Returns `true` if any of the collection elements matches the predicate.
  /// Complexity: O(n), n <= N
  func any(_ predicate: (Element) -> Bool) -> Bool {
    for element in self {
      if predicate(element) {
        return true
      }
    }
    return false
  }

  /// Returns `true` if all of the collection elements match the predicate.
  /// Complexity: O(n), n <= N
  @inlinable
  func all(_ predicate: (Element) -> Bool) -> Bool {
    guard !isEmpty else { return false }
    return !any { !predicate($0) }
  }
}
