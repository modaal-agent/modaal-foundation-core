// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import ModaalSupport
import UIKit

/// Strongly-held delegate proxy for `UIImagePickerController` in
/// **video** capture mode (camera recorder or video library). Companion
/// to `UIImagePickerControllerStillImageDelegateProxy` (still-image
/// capture): both classes are needed because `UIImagePickerController`
/// is one system VC for both modes but the `info[InfoKey: Any]` payload
/// differs — video capture vends a temp file URL under `.mediaURL`,
/// still-image capture vends a `UIImage` under `.editedImage` /
/// `.originalImage`.
///
/// UIKit holds `delegate` weakly, so the Router that presents the picker
/// MUST anchor this proxy in a Router-local property — otherwise the
/// proxy deallocates the moment `present(_:animated:)` returns and the
/// picker's delegate methods never invoke the handler.
///
/// Used alongside `ViewableRouter.presentModal(...)` when the Router
/// presents `UIImagePickerController` configured with
/// `sourceType = .camera` and `mediaTypes = ["public.movie"]` as a
/// UIKit-direct modal.
///
/// The `onCapture` handler receives the recorded video's temp file URL
/// (`info[.mediaURL]`), or `nil` if the user tapped Cancel or no usable
/// URL was vended.
public final class UIImagePickerControllerVideoDelegateProxy: NSObject,
                                                              UIImagePickerControllerDelegate,
                                                              UINavigationControllerDelegate {
  let onCapture: AnyActionHandler<URL?>

  public init(onCapture: AnyActionHandler<URL?>) {
    self.onCapture = onCapture
  }

  // MARK: - UIImagePickerControllerDelegate

  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    onCapture.invoke(info[.mediaURL] as? URL)
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    onCapture.invoke(nil)
  }
}
