// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import CombineRIBs
import UIKit

/// Everything the system hands *to* the app: incoming URLs, APNS callbacks, and
/// lifecycle transitions.
///
/// URLs and notifications are dispatched priority-first. Features register a
/// `URLHandling` or `NotificationHandling` conformer with a priority, and the
/// worker offers each event to the highest-priority handler that claims it
/// (chain-of-responsibility), stopping at the first one that does. APNS
/// device-token registration is the exception: it is broadcast to every
/// registered handler.
///
/// Lifecycle transitions are a publisher instead of a registration, because
/// every subscriber wants every event — there is nothing to arbitrate.
///
/// The worker holds registered handlers STRONGLY. To deregister, cancel the
/// `AnyCancellable` returned from `registerURLHandler` /
/// `registerAPNSNotificationsHandler` — in practice via
/// `.cancelOnDeactivate(interactor: self)` on the RIB interactor that registered
/// itself.
public final class InboundAppServicesWorker: Worker, InboundAppServicesWorking {

  private let lock = NSRecursiveLock()
  private var urlHandlers: [(URLHandling, AppServicePriority)] = []
  private var notificationHandlers: [(NotificationHandling, AppServicePriority)] = []

  /// Where lifecycle notifications come from. Injected rather than reached for,
  /// so a test can post into a `NotificationCenter()` of its own instead of
  /// into the one every other test in the process is listening to.
  private let notificationCenter: NotificationCenter

  /// - Parameter notificationCenter: The center to observe for lifecycle
  ///   transitions. Production passes nothing and gets `.default`, which is
  ///   where UIKit posts.
  public init(notificationCenter: NotificationCenter = .default) {
    self.notificationCenter = notificationCenter
    super.init()
  }

  // MARK: - AppServicesURLHandlerRegistering

  public func registerURLHandler(_ handler: URLHandling,
                                 priority: AppServicePriority) -> AnyCancellable {
    lock.synchronized {
      if let index = urlHandlers.firstIndex(where: { $0.0 === handler }) {
        urlHandlers[index].1 = priority
      } else {
        urlHandlers.append((handler, priority))
      }
    }

    return AnyCancellable { [weak self] in
      guard let self else { return }
      self.lock.synchronized {
        self.urlHandlers.removeAll(where: { $0.0 === handler })
      }
    }
  }

  // MARK: - AppServicesAPNSHandlerRegistering

  public func registerAPNSNotificationsHandler(_ handler: NotificationHandling,
                                               priority: AppServicePriority) -> AnyCancellable {
    lock.synchronized {
      if let index = notificationHandlers.firstIndex(where: { $0.0 === handler }) {
        notificationHandlers[index].1 = priority
      } else {
        notificationHandlers.append((handler, priority))
      }
    }

    return AnyCancellable { [weak self] in
      guard let self else { return }
      self.lock.synchronized {
        self.notificationHandlers.removeAll(where: { $0.0 === handler })
      }
    }
  }

  // MARK: - AppServiceURLHandling

  public func openURLContexts(_ urlContexts: [(url: URL, options: UIScene.OpenURLOptions?)]) {
    let handlers = lock.synchronized {
      urlHandlers.sorted(by: { $0.1.rawValue > $1.1.rawValue }).map { $0.0 }
    }

    for urlContext in urlContexts {
      let url = urlContext.url
      for handler in handlers where handler.canHandleOpenUrl(url) {
        handler.handleOpenUrl(url)
        break
      }
    }
  }

  public func openURL(_ url: URL, options: UIScene.OpenURLOptions?) {
    openURLContexts([(url: url, options: options)])
  }

  // MARK: - AppServiceNotificationHandling

  public func appDidRegisterForRemoteNotifications(deviceToken: Data) {
    let handlers = lock.synchronized { notificationHandlers.map { $0.0 } }
    for handler in handlers {
      handler.appDidRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
  }

  public func appDidReceiveRemoteNotification(notification: [AnyHashable: Any],
                                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let handlers = lock.synchronized {
      notificationHandlers.sorted(by: { $0.1.rawValue > $1.1.rawValue }).map { $0.0 }
    }

    for handler in handlers where handler.canHandleRemoteNotification(notification: notification, fetchCompletionHandler: completionHandler) {
      handler.handleRemoteNotification(notification: notification, fetchCompletionHandler: completionHandler)
      return
    }
  }

  // MARK: - AppLifecycleObserving

  public var appLifecycle: AnyPublisher<AppLifecycleEvent, Never> {
    // Built per subscription rather than stored: `NotificationCenter.publisher`
    // holds no state worth sharing, and a stored publisher would mean the
    // worker keeps observers alive for the process lifetime even when nothing
    // is listening.
    events(UIApplication.didBecomeActiveNotification, as: .didBecomeActive)
      .merge(
        with: events(UIApplication.willResignActiveNotification, as: .willResignActive),
        events(UIApplication.didEnterBackgroundNotification, as: .didEnterBackground),
        events(UIApplication.willEnterForegroundNotification, as: .willEnterForeground))
      .eraseToAnyPublisher()
  }

  private func events(
    _ name: Notification.Name,
    as event: AppLifecycleEvent) -> AnyPublisher<AppLifecycleEvent, Never> {
      notificationCenter.publisher(for: name)
        .map { _ in event }
        .eraseToAnyPublisher()
    }
}
