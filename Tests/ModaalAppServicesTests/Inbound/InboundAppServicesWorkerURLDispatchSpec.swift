// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation
@testable import ModaalAppServices
import Quick
import Nimble

final class InboundAppServicesWorkerURLDispatchSpec: QuickSpec {
  override static func spec() {
    describe("InboundAppServicesWorker URL dispatch") {

      // NOTE: AnyCancellable cancels itself on deinit (standard Combine
      // semantics). Tests MUST retain the cancellable returned from
      // `registerURLHandler` — otherwise the handler is immediately
      // deregistered and the spec is meaningless.

      context("priority ordering") {
        it("dispatches to the higher-priority handler when both claim the URL") {
          let worker = InboundAppServicesWorker()
          let highHandler = SpyURLHandler(canHandle: { _ in true })
          let defaultHandler = SpyURLHandler(canHandle: { _ in true })

          let url = makeURL("https://example.com/path")
          var bag: [AnyCancellable] = []
          bag.append(worker.registerURLHandler(defaultHandler, priority: .default))
          bag.append(worker.registerURLHandler(highHandler, priority: .high))

          worker.openURLContexts([(url: url, options: nil)])

          expect(highHandler.handleCalls) == [url]
          expect(defaultHandler.handleCalls).to(beEmpty())
          _ = bag  // keep registrations alive through the assertions
        }

        it("falls through to a lower-priority handler when the higher one declines") {
          let worker = InboundAppServicesWorker()
          let highDeclines = SpyURLHandler(canHandle: { _ in false })
          let defaultClaims = SpyURLHandler(canHandle: { _ in true })

          let url = makeURL("https://example.com/path")
          var bag: [AnyCancellable] = []
          bag.append(worker.registerURLHandler(defaultClaims, priority: .default))
          bag.append(worker.registerURLHandler(highDeclines, priority: .high))

          worker.openURLContexts([(url: url, options: nil)])

          expect(highDeclines.canHandleCalls) == [url]
          expect(highDeclines.handleCalls).to(beEmpty())
          expect(defaultClaims.handleCalls) == [url]
          _ = bag
        }
      } // /context priority ordering

      context("no matching handler") {
        it("invokes no handler and does not crash") {
          let worker = InboundAppServicesWorker()
          let handler = SpyURLHandler(canHandle: { _ in false })
          let cancellable = worker.registerURLHandler(handler, priority: .default)

          worker.openURLContexts([(url: makeURL("https://example.com"), options: nil)])

          expect(handler.handleCalls).to(beEmpty())
          expect(handler.canHandleCalls).to(haveCount(1))  // confirms handler was queried
          _ = cancellable
        }
      } // /context

      context("multiple URLs in a single dispatch") {
        it("invokes handleOpenUrl exactly once per matching URL") {
          let worker = InboundAppServicesWorker()
          let middleURL = makeURL("https://example.com/middle")
          let handler = SpyURLHandler(canHandle: { $0 == middleURL })
          let cancellable = worker.registerURLHandler(handler, priority: .default)

          worker.openURLContexts([
            (url: makeURL("https://example.com/one"), options: nil),
            (url: middleURL, options: nil),
            (url: makeURL("https://example.com/three"), options: nil),
          ])

          expect(handler.handleCalls) == [middleURL]
          _ = cancellable
        }
      } // /context

      context("re-registering the same handler") {
        it("updates its priority in place without duplicating the entry") {
          let worker = InboundAppServicesWorker()
          let shared = SpyURLHandler(canHandle: { _ in true })
          let other = SpyURLHandler(canHandle: { _ in true })

          var bag: [AnyCancellable] = []
          // shared starts at .fallback, then promoted to .high.
          bag.append(worker.registerURLHandler(shared, priority: .fallback))
          bag.append(worker.registerURLHandler(other, priority: .default))
          bag.append(worker.registerURLHandler(shared, priority: .high))

          worker.openURLContexts([(url: makeURL("https://example.com"), options: nil)])

          // If `shared` were duplicated, both `.fallback` and `.high` copies
          // would still be present and `other` (.default) would never win;
          // here we assert `shared` claimed the URL because its priority is
          // now `.high` (the highest of the three).
          expect(shared.handleCalls).to(haveCount(1))
          expect(other.handleCalls).to(beEmpty())
          _ = bag
        }
      } // /context

      context("openURL convenience") {
        it("dispatches a single URL through openURLContexts") {
          let worker = InboundAppServicesWorker()
          let url = makeURL("https://example.com/x")
          let handler = SpyURLHandler(canHandle: { _ in true })
          let cancellable = worker.registerURLHandler(handler, priority: .default)

          worker.openURL(url, options: nil)

          expect(handler.handleCalls) == [url]
          _ = cancellable
        }
      } // /context

      context("discarded AnyCancellable") {
        it("documents that handlers are deregistered when the cancellable is not retained") {
          // This is the inverse of the other tests — it verifies the Combine
          // contract that drives the `.cancelOnDeactivate(interactor:)` design.
          let worker = InboundAppServicesWorker()
          let handler = SpyURLHandler(canHandle: { _ in true })

          _ = worker.registerURLHandler(handler, priority: .default)
          // ^ the AnyCancellable is discarded immediately, which calls
          //   cancel() on deinit (standard Combine behavior).

          worker.openURLContexts([(url: makeURL("https://example.com"), options: nil)])

          expect(handler.handleCalls).to(beEmpty())
        }
      } // /context

    } // /describe
  }
}
