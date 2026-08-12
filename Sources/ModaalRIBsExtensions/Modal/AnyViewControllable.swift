// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import UIKit

/// Lightweight `ViewControllable` adapter for UIKit-vended view
/// controllers that aren't owned by a RIB — system pickers
/// (`PHPickerViewController`, `UIImagePickerController`,
/// `UIDocumentPickerViewController`, …), system alerts presented
/// through the Router, etc. Use when the caller already has a
/// `UIViewController` and needs to hand it to
/// `ViewableRouter.presentModal(...)`, which expects a
/// `ViewControllable`.
///
/// The wrapper holds the view controller strongly so the caller can
/// pass an inline `UIViewController(...)` construction without
/// retaining it themselves; the modal session's `ModalDismissToken`
/// keeps the wrapper alive through the present/dismiss cycle.
public final class AnyViewControllable: ViewControllable {
  public let uiviewController: UIViewController

  public init(_ uiViewController: UIViewController) {
    self.uiviewController = uiViewController
  }
}
