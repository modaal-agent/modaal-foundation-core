// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation

/// One app-lifecycle transition, as UIKit reports it.
///
/// The four cases are the ones an app actually branches on. `willResignActive`
/// fires for interruptions that do not background the app (a phone call, the
/// Control Centre pull-down, an incoming-call banner), so a game that pauses on
/// `.didEnterBackground` alone keeps running under the notification shade.
public enum AppLifecycleEvent: Equatable, Sendable {
  case didBecomeActive
  case willResignActive
  case didEnterBackground
  case willEnterForeground
}

/// The app's own lifecycle transitions, as a publisher.
///
/// Inbound, like the URL and notification handlers next to it: the system
/// decides when these arrive and the app reacts. It differs from those two in
/// how it is consumed — every subscriber gets every event, so there is no
/// priority and nothing to claim, and a publisher is the right shape.
///
/// It exists as a protocol because `NotificationCenter.default` is a singleton.
/// A feature that subscribes to it directly cannot be unit-tested without
/// posting real `UIApplication` notifications into the process running the
/// tests, where they reach every other test doing the same thing.
///
/// Features depend on this protocol and subscribe with
/// `.cancelOnDeactivate(interactor:)`, like any other publisher. Tests
/// substitute a stub, or construct
/// `InboundAppServicesWorker(notificationCenter:)` with a private
/// `NotificationCenter()` and post into it.
///
/// **Threading**: UIKit posts these notifications on the main thread, so the
/// publisher delivers on main. It does not `receive(on:)` — adding a hop would
/// turn a synchronous pause into one that lands a runloop turn late, which for
/// `willResignActive` is after the snapshot the system takes.
///
/// sourcery: CreateMock
public protocol AppLifecycleObserving: AnyObject {
  /// Every lifecycle transition, in the order UIKit posts them. Multiple
  /// subscribers are fine; each gets its own subscription to the underlying
  /// notifications.
  var appLifecycle: AnyPublisher<AppLifecycleEvent, Never> { get }
}
