// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import UIKit
import CombineRIBs
import SwiftUI

public protocol NavigationControllable: ViewControllable {
  var uiNavigationController: UINavigationController { get }

  func push(_ viewController: ViewControllable, animated: Bool)
  func pop(animated: Bool)
  func present(_ viewController: ViewControllable, animated: Bool)
  func present(_ viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
  func dismiss(animated: Bool)
  func dismiss(animated: Bool, completion: (() -> ())?)
}

public extension NavigationControllable where Self: UINavigationController {
  var uiNavigationController: UINavigationController {
    return self
  }

  func push(_ viewController: ViewControllable, animated: Bool) {
    pushViewController(viewController.uiviewController, animated: animated)
  }

  func pop(animated: Bool) {
    popViewController(animated: animated)
  }

  func present(_ viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
    present(viewController.uiviewController, animated: animated, completion: completion)
  }

  func present(_ viewController: ViewControllable, animated: Bool) {
    present(viewController, animated: animated, completion: nil)
  }

  func dismiss(animated: Bool, completion: (() -> ())?) {
    dismiss(animated: true, completion: completion)
  }

  func dismiss(animated: Bool) {
    dismiss(animated: true, completion: nil)
  }
}

extension UINavigationController: @retroactive ViewControllable, NavigationControllable {}
