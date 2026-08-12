// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import PhotosUI
import ModaalSupport

/// Strongly-held delegate proxy for `PHPickerViewController`. UIKit
/// holds `delegate` weakly, so the Router that presents the picker MUST
/// anchor this proxy in a Router-local property — otherwise the proxy
/// deallocates the moment `present(_:animated:)` returns and
/// `picker(_:didFinishPicking:)` never invokes the handler.
///
/// Mirrors the shape of `UIPresentationControllerDelegateProxy`. Used
/// alongside `ViewableRouter.presentModal(...)` (with the picker wrapped
/// in `AnyViewControllable`) when the Router presents a
/// `PHPickerViewController` as a UIKit-direct modal.
///
/// When the Router exposes a `dismissPicker(completion:)` method that
/// calls `dismissModal(_:completion:)`, the Interactor's result handler
/// can apply the chained-dismissal recipe (inner dismiss → `+25 ms`
/// `DispatchQueue.main.asyncAfter` hop → listener fire) to teardown a
/// chain of modals across RIB boundaries without leaking UIKit-tracked
/// VCs.
public final class PHPickerResultsHandlerProxy: NSObject, PHPickerViewControllerDelegate {
  let onResults: AnyActionHandler<[PHPickerResult]>

  public init(onResults: AnyActionHandler<[PHPickerResult]>) {
    self.onResults = onResults
  }

  // MARK: - PHPickerViewControllerDelegate

  public func picker(_ picker: PHPickerViewController,
                     didFinishPicking results: [PHPickerResult]) {
    onResults.invoke(results)
  }
}
