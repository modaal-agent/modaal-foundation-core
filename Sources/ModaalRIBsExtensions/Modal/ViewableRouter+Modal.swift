// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import ModaalSupport
import UIKit

/// Opaque token returned by `ViewableRouter.presentModal(...)`. Pass back
/// to `dismissModal(_:animated:completion:)` to tear down the modal
/// session. Calling `dismissModal` after the token has already been
/// retired (interactive swipe-down already fired, or `dismissModal` was
/// already called) is an idempotent no-op — `completion` fires
/// synchronously on the no-op path so the caller's chained-dismissal
/// sequencing still runs.
///
/// The token holds the `UIPresentationControllerDelegateProxy` strongly —
/// UIKit's `UIPresentationController.delegate` is a weak reference, so
/// without this anchor the proxy would deallocate the moment
/// `presentModal` returned and swipe-down dismissals would never invoke
/// `onDismiss`.
public final class ModalDismissToken {
  fileprivate weak var presented: UIViewController?
  fileprivate let delegate: UIPresentationControllerDelegateProxy
  fileprivate var retired: Bool = false

  fileprivate init(presented: UIViewController,
                   delegate: UIPresentationControllerDelegateProxy) {
    self.presented = presented
    self.delegate = delegate
  }
}

public extension ViewableRouter {

  /// Modally presents `child` on top of this router's
  /// `viewControllable.uiviewController`. The Router owns the `present`
  /// and `dismiss` calls symmetrically — this is the canonical
  /// replacement for hosting a child RIB's `UIViewController` inside a
  /// SwiftUI `.sheet` / `.fullScreenCover` / `.popover`.
  ///
  /// - Parameters:
  ///   - child: The child RIB's `ViewControllable` to present. For
  ///     non-RIB UIKit-vended view controllers (system pickers, alerts),
  ///     wrap with `AnyViewControllable`.
  ///   - animated: Whether to animate the presentation transition.
  ///   - configure: Optional configuration block invoked with the
  ///     presented VC's `UISheetPresentationController` (if any) — tune
  ///     `detents`, `prefersGrabberVisible`, large-title behavior, etc.
  ///     The block runs *before* `present(_:animated:)` is called.
  ///   - shouldDismiss: Optional synchronous `Bool` query UIKit calls
  ///     before allowing an interactive dismissal. Return `false` to
  ///     block swipe-down (UIKit will then fire `didAttemptToDismiss`).
  ///     Default `nil` ⇒ always allow. Canonical use: gate "swipe-down
  ///     on a dirty draft".
  ///   - didAttemptToDismiss: Optional handler fired when an interactive
  ///     dismissal was blocked by `shouldDismiss` returning `false`.
  ///     Canonical use: trigger a "Discard changes?" confirmation alert.
  ///   - onDismiss: Fires once when the user dismisses the sheet
  ///     interactively (swipe-down). UIKit only invokes
  ///     `presentationControllerDidDismiss` for user-initiated
  ///     dismissals — programmatic `dismissModal(_:)` does NOT fire this
  ///     handler. This is the parent Interactor's seam for tearing down
  ///     the child RIB on swipe-down.
  /// - Returns: A `ModalDismissToken` to store on the Router and pass to
  ///   `dismissModal(_:animated:completion:)` in the matching detach
  ///   method. Discarding the token (`_ = router.presentModal(...)`) is
  ///   a bug — without it, the Router cannot dismiss the session and
  ///   the chained-dismissal recipe breaks.
  @discardableResult
  func presentModal(_ child: ViewControllable,
                    animated: Bool = true,
                    configure: ((UISheetPresentationController) -> Void)? = nil,
                    shouldDismiss: (() -> Bool)? = nil,
                    didAttemptToDismiss: AnyActionHandler<Void>? = nil,
                    onDismiss: AnyActionHandler<Void>) -> ModalDismissToken {
    let parent = viewControllable.uiviewController
    let presented = child.uiviewController
    let proxy = UIPresentationControllerDelegateProxy(
      didDismissHandler: onDismiss,
      shouldDismissHandler: shouldDismiss,
      didAttemptToDismissHandler: didAttemptToDismiss)
    if let sheet = presented.sheetPresentationController {
      configure?(sheet)
    }
    presented.presentationController?.delegate = proxy
    // If the parent is already presenting another view controller —
    // typically a SwiftUI `.sheet` whose binding setter just flipped to
    // `false` but whose `UIHostingController` is still attached to
    // UIKit's presentation chain — UIKit will refuse the new
    // `present(_:animated:)` with "which is already presenting…".
    // Dismiss the existing top sheet first, then present in the
    // completion. The common trigger is "tap a row in a SwiftUI sheet
    // that opens a Router-owned modal".
    if let existing = parent.presentedViewController {
      existing.dismiss(animated: animated) {
        parent.present(presented, animated: animated)
      }
    } else {
      parent.present(presented, animated: animated)
    }
    return ModalDismissToken(presented: presented, delegate: proxy)
  }

  /// Programmatically dismisses the modal session represented by `token`.
  /// Safe to call after the user has already dismissed interactively or
  /// after a prior `dismissModal(_:)` — both paths mark the token as
  /// retired and subsequent calls become no-ops with `completion` fired
  /// synchronously.
  ///
  /// **Chained dismissal**: when the presented VC itself owns a child
  /// modal (e.g. a Router-owned RIB has presented a system picker on top
  /// of its own VC), the Interactor's result handler MUST sequence the
  /// dismissals — issue the inner dismiss first, wait for its
  /// `completion` plus a `+25 ms` `DispatchQueue.main.asyncAfter` hop,
  /// **then** fire any listener callback that would transitively trigger
  /// the outer dismiss. Issuing the outer dismiss while the inner is
  /// still in flight causes UIKit to silently drop it (per Apple's
  /// "calls to this method are ignored when the receiver is being
  /// dismissed by another animation" rule), and the outer VC leaks.
  /// See `docs/ModaalRIBsExtensions.md` for the full recipe.
  func dismissModal(_ token: ModalDismissToken,
                    animated: Bool = true,
                    completion: (() -> Void)? = nil) {
    guard !token.retired else {
      completion?()
      return
    }
    token.retired = true
    guard let presented = token.presented else {
      completion?()
      return
    }
    presented.dismiss(animated: animated, completion: completion)
  }
}
