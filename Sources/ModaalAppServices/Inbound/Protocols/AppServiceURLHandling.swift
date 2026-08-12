// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import UIKit

/// External-facing URL dispatch contract — called by `SceneDelegate` (and by
/// any in-app code wishing to invoke a URL programmatically). The composition
/// root (`RootInteractor`) conforms to this and delegates to `InboundAppServicesWorker`.
///
/// sourcery: CreateMock
public protocol AppServiceURLHandling {
  func openURLContexts(_ urlContexts: [(url: URL, options: UIScene.OpenURLOptions?)])
  func openURL(_ url: URL, options: UIScene.OpenURLOptions?)
}

public extension AppServiceURLHandling {
  func openURL(_ url: URL, options: UIScene.OpenURLOptions? = nil) {
    openURLContexts([(url: url, options: options)])
  }
}
