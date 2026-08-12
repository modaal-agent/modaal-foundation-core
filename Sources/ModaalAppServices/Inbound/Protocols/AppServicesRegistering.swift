// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation

/// Registration API exposed to RIB interactors that want to receive URLs.
/// The returned `AnyCancellable` MUST be bound to the interactor's lifecycle
/// via `.cancelOnDeactivate(interactor: self)` — the worker retains the
/// handler strongly until the cancellable is cancelled.
///
/// sourcery: CreateMock
public protocol AppServicesURLHandlerRegistering {
  func registerURLHandler(_ handler: URLHandling,
                          priority: AppServicePriority) -> AnyCancellable
}

/// Registration API exposed to RIB interactors that want to receive APNS
/// callbacks. Same cancellation contract as `AppServicesURLHandlerRegistering`.
///
/// sourcery: CreateMock
public protocol AppServicesAPNSHandlerRegistering {
  func registerAPNSNotificationsHandler(_ handler: NotificationHandling,
                                        priority: AppServicePriority) -> AnyCancellable
}

/// Composed registration API — the `RootComponent` exposes this to child RIBs
/// as `appServicesRegister: AppServicesRegistering`.
///
/// sourcery: CreateMock
public protocol AppServicesRegistering: AppServicesURLHandlerRegistering,
                                        AppServicesAPNSHandlerRegistering {
}
