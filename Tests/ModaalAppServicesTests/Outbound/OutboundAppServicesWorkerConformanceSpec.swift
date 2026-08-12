// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import Nimble
import Quick
import UIKit
@testable import ModaalAppServices

/// Smoke spec for `OutboundAppServicesWorker`. The worker is a 1-line facade
/// over UIKit / AppTrackingTransparency / UserNotifications singletons with no
/// branching logic — there's nothing meaningful to assert about those method
/// bodies without method swizzling or UIKit fakes. The contract that matters is
/// "every shipped narrow protocol resolves to the same concrete worker", which
/// this spec catches against accidental signature drift.
///
/// When adding a new outbound narrow protocol to `OutboundAppServicesWorking`:
///   1. Add the conformance assertion below.
///   2. The compiler-driven `expect(worker as NewProtocol)` would only fail
///      to compile if the worker stops conforming — so the assertion's main
///      value is documenting which protocols the worker is contractually
///      bound to.
final class OutboundAppServicesWorkerConformanceSpec: QuickSpec {
  override class func spec() {
    describe("OutboundAppServicesWorker") {
      it("constructs successfully") {
        expect(OutboundAppServicesWorker()).toNot(beNil())
      }

      it("is a RIBs Worker — lifecycle hooks (didStart / didStop) are available") {
        let worker = OutboundAppServicesWorker()
        expect(worker as Working).toNot(beNil())
      }

      it("conforms to every shipped narrow outbound protocol") {
        let worker = OutboundAppServicesWorker()
        expect(worker as URLOpening).toNot(beNil())
        expect(worker as PasteboardReading).toNot(beNil())
        expect(worker as PasteboardWriting).toNot(beNil())
        expect(worker as HapticFeedbackProviding).toNot(beNil())
        expect(worker as AppTrackingAuthorizationRequesting).toNot(beNil())
        expect(worker as PushNotificationAuthorizationRequesting).toNot(beNil())
        expect(worker as AudioSessionConfiguring).toNot(beNil())
        expect(worker as OutboundAppServicesWorking).toNot(beNil())
      }
    }
  }
}
