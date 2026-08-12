// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import UserNotifications

/// Wraps the push-notification permission prompt
/// (`UNUserNotificationCenter.current().requestAuthorization`) and the
/// matching `UIApplication.shared.registerForRemoteNotifications()` call
/// that drives the APNS device-token callback consumed by inbound
/// `NotificationHandling` conformers in the app. Idempotent: registers iff
/// currently authorized; prompts iff currently `.notDetermined`. This is
/// the only code in the app that touches `UNUserNotificationCenter.current()`
/// for authorization or
/// `UIApplication.shared.registerForRemoteNotifications()`.
///
/// Interactors MUST depend on this protocol rather than calling
/// `UNUserNotificationCenter.current().requestAuthorization` or
/// `UIApplication.shared.registerForRemoteNotifications()` directly.
///
/// sourcery: CreateMock
public protocol PushNotificationAuthorizationRequesting: AnyObject {
  /// Default options requested by `OutboundAppServicesWorker`: `[.alert, .badge, .sound]`.
  /// If a caller needs `.provisional` or `.criticalAlert`, add a second
  /// method on this protocol — don't widen this one. The implementation
  /// reads the current authorization status first and only prompts on
  /// `.notDetermined`; on `.authorized` / `.ephemeral` / `.provisional` it
  /// calls `registerForRemoteNotifications()` immediately.
  func requestPushAuthorizationIfNeeded()
}
