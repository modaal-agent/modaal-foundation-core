// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

public protocol OptionalType {
  associatedtype Wrapped
  func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> U?
}

extension Optional: OptionalType {
}
