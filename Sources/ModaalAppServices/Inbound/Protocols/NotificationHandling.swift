// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import UIKit

/// Per-handler APNS contract — implemented by RIB interactors that want to
/// receive APNS callbacks. Register with `AppServicesRegistering.registerAPNSNotificationsHandler`.
///
/// `appDidRegisterForRemoteNotifications(deviceToken:)` is **broadcast** to all
/// registered handlers — every handler receives the token. The
/// `canHandleRemoteNotification` / `handleRemoteNotification` pair is
/// chain-of-responsibility: handlers are tried in priority order, the first
/// returning `true` wins, and the remaining handlers are skipped.
///
/// sourcery: CreateMock
public protocol NotificationHandling: AnyObject {
  func appDidRegisterForRemoteNotifications(deviceToken: Data)

  func canHandleRemoteNotification(notification: [AnyHashable: Any],
                                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool
  func handleRemoteNotification(notification: [AnyHashable: Any],
                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
}
