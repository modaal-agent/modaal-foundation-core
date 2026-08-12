// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import CombineRIBs
import Nimble
import Quick
import UIKit
@testable import ModaalAppServices

/// `AppLifecycleObserving` is the one inbound contract with behaviour worth
/// asserting directly, and the reason the worker's initializer takes a
/// `NotificationCenter` at all: posting into `.default` from a test would reach
/// every other subscriber in the process, so the injected center is what makes
/// this assertable.
final class InboundAppServicesWorkerAppLifecycleSpec: QuickSpec {
  override class func spec() {
    describe("InboundAppServicesWorker app lifecycle") {
      it("conforms to AppLifecycleObserving") {
        expect(InboundAppServicesWorker() as AppLifecycleObserving).toNot(beNil())
      }

      it("republishes UIKit's lifecycle notifications, in order") {
        let center = NotificationCenter()
        let worker = InboundAppServicesWorker(notificationCenter: center)

        var received: [AppLifecycleEvent] = []
        let subscription = worker.appLifecycle.sink { received.append($0) }
        defer { subscription.cancel() }

        center.post(name: UIApplication.willResignActiveNotification, object: nil)
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        expect(received).to(equal([
          .willResignActive,
          .didEnterBackground,
          .willEnterForeground,
          .didBecomeActive,
        ]))
      }

      it("ignores the center it was not given") {
        let worker = InboundAppServicesWorker(notificationCenter: NotificationCenter())

        var received: [AppLifecycleEvent] = []
        let subscription = worker.appLifecycle.sink { received.append($0) }
        defer { subscription.cancel() }

        NotificationCenter.default.post(
          name: UIApplication.didEnterBackgroundNotification, object: nil)

        expect(received).to(beEmpty())
      }

      it("stops delivering once the subscription is cancelled") {
        let center = NotificationCenter()
        let worker = InboundAppServicesWorker(notificationCenter: center)

        var received: [AppLifecycleEvent] = []
        let subscription = worker.appLifecycle.sink { received.append($0) }
        subscription.cancel()

        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        expect(received).to(beEmpty())
      }

      // Dispatch and lifecycle share one worker, so the composite is what the
      // composition root stores. Asserting it here keeps the move of
      // AppLifecycleObserving onto the inbound side from silently regressing.
      it("resolves the composed inbound contract") {
        let worker = InboundAppServicesWorker()
        expect(worker as InboundAppServicesWorking).toNot(beNil())
        expect(worker as AppServicesRegistering).toNot(beNil())
        expect(worker as AppServiceHandling).toNot(beNil())
      }
    }
  }
}
