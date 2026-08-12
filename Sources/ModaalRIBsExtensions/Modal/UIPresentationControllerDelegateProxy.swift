// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import ModaalSupport
import UIKit

/// Strongly-held `UIAdaptivePresentationControllerDelegate` proxy. UIKit
/// holds `UIPresentationController.delegate` weakly, so a Router that
/// presents a modal MUST anchor this proxy in a Router-local property —
/// otherwise the proxy deallocates the moment `present(_:animated:)`
/// returns and the dismiss callbacks never fire.
///
/// The proxy supports three independently-optional behaviors, threaded
/// through `AnyActionHandler` for testability:
///
/// - `didDismissHandler` (always present): fires once when the user
///   dismisses the sheet interactively (typically swipe-down).
///   `presentationControllerDidDismiss(_:)` is NOT called for
///   programmatic dismissals — those go through
///   `ViewableRouter.dismissModal(_:)` and the parent Interactor is
///   notified by a different path (a listener callback).
///
/// - `shouldDismissHandler` (optional): synchronous `Bool` query UIKit
///   calls before allowing an interactive dismissal. Return `false` to
///   block the swipe-down (UIKit will then fire
///   `didAttemptToDismissHandler`). Return `true` (or omit the handler
///   entirely) to allow the dismissal. Canonical use: gate "swipe-down
///   on a dirty draft" — e.g. a multi-step wizard whose Presenter
///   exposes an `isDirty` flag.
///
/// - `didAttemptToDismissHandler` (optional): fires when the user
///   attempted an interactive dismissal that was blocked by
///   `shouldDismissHandler` returning `false`. Canonical use: trigger
///   a "Discard changes?" confirmation alert.
public class UIPresentationControllerDelegateProxy: NSObject, UIAdaptivePresentationControllerDelegate {
  let didDismissHandler: AnyActionHandler<Void>
  let shouldDismissHandler: (() -> Bool)?
  let didAttemptToDismissHandler: AnyActionHandler<Void>?

  public init(didDismissHandler: AnyActionHandler<Void>,
              shouldDismissHandler: (() -> Bool)? = nil,
              didAttemptToDismissHandler: AnyActionHandler<Void>? = nil) {
    self.didDismissHandler = didDismissHandler
    self.shouldDismissHandler = shouldDismissHandler
    self.didAttemptToDismissHandler = didAttemptToDismissHandler
  }

  // MARK: - UIAdaptivePresentationControllerDelegate

  public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    shouldDismissHandler?() ?? true
  }

  public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
    didAttemptToDismissHandler?.invoke(())
  }

  public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    didDismissHandler.invoke(())
  }
}
