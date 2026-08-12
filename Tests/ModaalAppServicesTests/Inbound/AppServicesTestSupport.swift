// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
import UIKit
@testable import ModaalAppServices

/// Spy URL handler — records every `canHandleOpenUrl` query and every
/// `handleOpenUrl` invocation. `canHandle` is a configurable predicate so
/// individual specs can model "claims the URL" vs. "does not claim the URL".
final class SpyURLHandler: URLHandling {
  var canHandle: (URL) -> Bool
  private(set) var canHandleCalls: [URL] = []
  private(set) var handleCalls: [URL] = []

  init(canHandle: @escaping (URL) -> Bool = { _ in false }) {
    self.canHandle = canHandle
  }

  func canHandleOpenUrl(_ url: URL) -> Bool {
    canHandleCalls.append(url)
    return canHandle(url)
  }

  func handleOpenUrl(_ url: URL) {
    handleCalls.append(url)
  }
}

/// Spy APNS handler — records token registrations and remote-notification
/// dispatch. `canHandle` is a configurable predicate for chain-of-responsibility
/// modelling.
final class SpyNotificationHandler: NotificationHandling {
  var canHandle: ([AnyHashable: Any]) -> Bool
  private(set) var tokenRegistrations: [Data] = []
  private(set) var canHandleCalls: [[AnyHashable: Any]] = []
  private(set) var handleCalls: [[AnyHashable: Any]] = []

  init(canHandle: @escaping ([AnyHashable: Any]) -> Bool = { _ in false }) {
    self.canHandle = canHandle
  }

  func appDidRegisterForRemoteNotifications(deviceToken: Data) {
    tokenRegistrations.append(deviceToken)
  }

  func canHandleRemoteNotification(notification: [AnyHashable: Any],
                                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
    canHandleCalls.append(notification)
    return canHandle(notification)
  }

  func handleRemoteNotification(notification: [AnyHashable: Any],
                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    handleCalls.append(notification)
  }
}

func makeURL(_ string: String) -> URL {
  URL(string: string)!
}
