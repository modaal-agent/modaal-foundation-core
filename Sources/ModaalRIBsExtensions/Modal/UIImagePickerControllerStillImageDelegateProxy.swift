// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import ModaalSupport
import UIKit

/// Strongly-held delegate proxy for `UIImagePickerController` in **still
/// image** capture mode. Companion to
/// `UIImagePickerControllerVideoDelegateProxy` (video capture): both
/// classes are needed because `UIImagePickerController` is one system
/// VC for both modes but the `info[InfoKey: Any]` payload differs —
/// still-image capture vends a `UIImage` under `.editedImage` /
/// `.originalImage`, video capture vends a temp file URL under
/// `.mediaURL`.
///
/// UIKit holds `delegate` weakly, so the Router that presents the picker
/// MUST anchor this proxy in a Router-local property — otherwise the
/// proxy deallocates the moment `present(_:animated:)` returns and the
/// picker's delegate methods never invoke the handler.
///
/// The `onCapture` handler receives the user-selected `UIImage` (the
/// `.editedImage` if cropping was enabled, otherwise the
/// `.originalImage`), or `nil` if the user tapped Cancel or no image
/// could be extracted from the selection.
public final class UIImagePickerControllerStillImageDelegateProxy: NSObject,
                                                                  UIImagePickerControllerDelegate,
                                                                  UINavigationControllerDelegate {
  let onCapture: AnyActionHandler<UIImage?>

  public init(onCapture: AnyActionHandler<UIImage?>) {
    self.onCapture = onCapture
  }

  // MARK: - UIImagePickerControllerDelegate

  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
    onCapture.invoke(image)
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    onCapture.invoke(nil)
  }
}
