// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import SwiftUI
import UIKit

extension View {
  public func snapshot() -> UIImage {
    let controller = UIHostingController(rootView: self.ignoresSafeArea(.all))
    let view = controller.view

    let targetSize = controller.view.intrinsicContentSize
    view?.bounds = CGRect(origin: .zero, size: targetSize)
    view?.backgroundColor = .clear

    let renderer = UIGraphicsImageRenderer(size: targetSize)

    return renderer.image { _ in
      view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
  }
}
