// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation
@testable import ModaalAppServices
import Quick
import Nimble

final class InboundAppServicesWorkerRegistrationLifecycleSpec: QuickSpec {
  override static func spec() {
    describe("InboundAppServicesWorker handler registration lifecycle") {

      context("URL handler") {
        it("stops receiving dispatches once the AnyCancellable is cancelled") {
          let worker = InboundAppServicesWorker()
          let handler = SpyURLHandler(canHandle: { _ in true })
          let cancellable = worker.registerURLHandler(handler, priority: .default)

          let url = makeURL("https://example.com")
          worker.openURLContexts([(url: url, options: nil)])
          expect(handler.handleCalls) == [url]

          cancellable.cancel()
          worker.openURLContexts([(url: url, options: nil)])

          expect(handler.handleCalls) == [url]  // unchanged after cancel
        }

        it("survives the cancellable going out of scope (AnyCancellable cancels on deinit)") {
          let worker = InboundAppServicesWorker()
          let handler = SpyURLHandler(canHandle: { _ in true })

          do {
            let cancellable = worker.registerURLHandler(handler, priority: .default)
            _ = cancellable  // hold for one statement; goes out of scope after
          }

          // After the scope exits, AnyCancellable was deallocated → it cancels
          // itself → handler is deregistered.
          worker.openURLContexts([(url: makeURL("https://example.com"), options: nil)])
          expect(handler.handleCalls).to(beEmpty())
        }
      } // /context URL handler

      context("APNS handler") {
        it("stops receiving dispatches once the AnyCancellable is cancelled") {
          let worker = InboundAppServicesWorker()
          let handler = SpyNotificationHandler(canHandle: { _ in true })
          let cancellable = worker.registerAPNSNotificationsHandler(handler, priority: .default)

          let payload: [AnyHashable: Any] = ["aps": ["alert": "hi"]]
          worker.appDidReceiveRemoteNotification(notification: payload, fetchCompletionHandler: { _ in })
          expect(handler.handleCalls).to(haveCount(1))

          cancellable.cancel()
          worker.appDidReceiveRemoteNotification(notification: payload, fetchCompletionHandler: { _ in })

          expect(handler.handleCalls).to(haveCount(1))  // unchanged after cancel
        }

        it("stops broadcasting token registrations once cancelled") {
          let worker = InboundAppServicesWorker()
          let handler = SpyNotificationHandler()
          let cancellable = worker.registerAPNSNotificationsHandler(handler, priority: .default)

          worker.appDidRegisterForRemoteNotifications(deviceToken: Data([0x01]))
          expect(handler.tokenRegistrations).to(haveCount(1))

          cancellable.cancel()
          worker.appDidRegisterForRemoteNotifications(deviceToken: Data([0x02]))

          expect(handler.tokenRegistrations).to(haveCount(1))
        }
      } // /context APNS handler

      context("worker deallocation") {
        it("does not crash when the cancellable outlives a deallocated worker") {
          let handler = SpyURLHandler()
          var cancellable: AnyCancellable?

          autoreleasepool {
            let worker = InboundAppServicesWorker()
            cancellable = worker.registerURLHandler(handler, priority: .default)
            _ = worker
          }

          // Worker is gone; cancelling now exercises the `[weak self]` guard
          // inside the AnyCancellable closure.
          cancellable?.cancel()
        }
      } // /context

    } // /describe
  }
}
