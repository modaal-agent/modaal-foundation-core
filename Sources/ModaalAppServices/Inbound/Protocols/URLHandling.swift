// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// Per-handler URL contract — implemented by RIB interactors that want to
/// claim incoming URLs. Register with `AppServicesRegistering.registerURLHandler`.
///
/// `canHandleOpenUrl(_:)` MUST be a **pure predicate** with no side effects.
/// The worker may call it on multiple handlers before finding the first match;
/// causing side effects there would process URLs twice. Do the work in
/// `handleOpenUrl(_:)` only.
///
/// sourcery: CreateMock
public protocol URLHandling: AnyObject {
  func canHandleOpenUrl(_ url: URL) -> Bool
  func handleOpenUrl(_ url: URL)
}
