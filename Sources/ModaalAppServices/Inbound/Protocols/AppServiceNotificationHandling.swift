// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import UIKit

/// External-facing APNS dispatch contract — called by `SceneDelegate` after
/// `AppDelegate` fans out APNS callbacks to its connected scenes. The
/// composition root (`RootInteractor`) conforms to this and delegates to
/// `InboundAppServicesWorker`.
///
/// sourcery: CreateMock
public protocol AppServiceNotificationHandling {
  func appDidRegisterForRemoteNotifications(deviceToken: Data)
  func appDidReceiveRemoteNotification(notification: [AnyHashable: Any],
                                       fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
}
