// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation
import UIKit
@testable import ModaalAppServices
import Quick
import Nimble

final class InboundAppServicesWorkerAPNSDispatchSpec: QuickSpec {
  override static func spec() {
    describe("InboundAppServicesWorker APNS dispatch") {

      // NOTE: AnyCancellable cancels itself on deinit (standard Combine
      // semantics). Tests MUST retain the cancellable returned from
      // `registerAPNSNotificationsHandler` — otherwise the handler is
      // immediately deregistered.

      context("device-token registration") {
        it("broadcasts the token to every registered handler") {
          let worker = InboundAppServicesWorker()
          let handler1 = SpyNotificationHandler()
          let handler2 = SpyNotificationHandler()

          var bag: [AnyCancellable] = []
          bag.append(worker.registerAPNSNotificationsHandler(handler1, priority: .default))
          bag.append(worker.registerAPNSNotificationsHandler(handler2, priority: .high))

          let token = Data([0xDE, 0xAD, 0xBE, 0xEF])
          worker.appDidRegisterForRemoteNotifications(deviceToken: token)

          expect(handler1.tokenRegistrations) == [token]
          expect(handler2.tokenRegistrations) == [token]
          _ = bag
        }
      } // /context

      context("incoming remote notification") {
        it("dispatches to the higher-priority handler when both claim it") {
          let worker = InboundAppServicesWorker()
          let high = SpyNotificationHandler(canHandle: { _ in true })
          let dflt = SpyNotificationHandler(canHandle: { _ in true })

          var bag: [AnyCancellable] = []
          bag.append(worker.registerAPNSNotificationsHandler(dflt, priority: .default))
          bag.append(worker.registerAPNSNotificationsHandler(high, priority: .high))

          let payload: [AnyHashable: Any] = ["aps": ["alert": "hi"]]
          worker.appDidReceiveRemoteNotification(notification: payload, fetchCompletionHandler: { _ in })

          expect(high.handleCalls).to(haveCount(1))
          expect(dflt.handleCalls).to(beEmpty())
          _ = bag
        }

        it("falls through to a lower-priority handler when the higher one declines") {
          let worker = InboundAppServicesWorker()
          let highDeclines = SpyNotificationHandler(canHandle: { _ in false })
          let defaultClaims = SpyNotificationHandler(canHandle: { _ in true })

          var bag: [AnyCancellable] = []
          bag.append(worker.registerAPNSNotificationsHandler(defaultClaims, priority: .default))
          bag.append(worker.registerAPNSNotificationsHandler(highDeclines, priority: .high))

          let payload: [AnyHashable: Any] = ["aps": ["alert": "hi"]]
          worker.appDidReceiveRemoteNotification(notification: payload, fetchCompletionHandler: { _ in })

          expect(highDeclines.canHandleCalls).to(haveCount(1))
          expect(highDeclines.handleCalls).to(beEmpty())
          expect(defaultClaims.handleCalls).to(haveCount(1))
          _ = bag
        }

        it("invokes no handler when none claim the notification") {
          let worker = InboundAppServicesWorker()
          let handler = SpyNotificationHandler(canHandle: { _ in false })
          let cancellable = worker.registerAPNSNotificationsHandler(handler, priority: .default)

          worker.appDidReceiveRemoteNotification(notification: [:], fetchCompletionHandler: { _ in })

          expect(handler.handleCalls).to(beEmpty())
          expect(handler.canHandleCalls).to(haveCount(1))
          _ = cancellable
        }
      } // /context

    } // /describe
  }
}
