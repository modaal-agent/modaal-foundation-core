// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Dispatch
import Foundation
@testable import ModaalAppServices
import Quick
import Nimble

/// Smoke test for the `NSRecursiveLock`-guarded handler arrays. We can't
/// *prove* thread safety here, but we drive concurrent registrations and
/// dispatches simultaneously — any obvious data race (e.g. mutation during
/// `sorted(by:)`) tends to crash under TSAN or sporadically under repeated runs.
final class InboundAppServicesWorkerThreadSafetySpec: QuickSpec {
  override static func spec() {
    describe("InboundAppServicesWorker thread safety smoke") {

      it("survives concurrent registrations and dispatches without crashing") {
        let worker = InboundAppServicesWorker()
        var cancellables: [AnyCancellable] = []
        let cancellablesLock = NSLock()
        let iterations = 100

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
          let handler = SpyURLHandler(canHandle: { _ in true })
          let cancellable = worker.registerURLHandler(handler, priority: .default)
          cancellablesLock.lock()
          cancellables.append(cancellable)
          cancellablesLock.unlock()

          worker.openURLContexts([(url: makeURL("https://example.com/\(UUID().uuidString)"), options: nil)])
        }

        expect(cancellables).to(haveCount(iterations))

        // Cancel half the registrations while dispatching concurrently.
        DispatchQueue.concurrentPerform(iterations: iterations / 2) { idx in
          cancellables[idx].cancel()
          worker.openURLContexts([(url: makeURL("https://example.com/post-\(idx)"), options: nil)])
        }
      }

    } // /describe
  }
}
