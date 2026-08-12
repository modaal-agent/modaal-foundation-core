// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation

/// Combine bridge over `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`.
/// Returns the in-memory `Data` payload for the requested UTI, or fails with
/// the error the system supplies. Used by Interactors that consume
/// `PHPickerResult`s or drag-and-drop providers — the Interactor receives the
/// `NSItemProvider` from a `PHPickerResultsHandlerProxy` callback and reaches
/// for `loadDataPublisher` instead of authoring its own
/// `Future { promise in provider.loadDataRepresentation(...) { … } }`.
///
/// Subscription semantics: `Deferred` defers the underlying `loadDataRepresentation`
/// call until subscribe-time, so each subscription re-runs the work. The
/// closure captures only `provider`, `typeIdentifier`, and the `promise` —
/// no `self`, no Interactor reference — so the subscription's cancellation
/// reliably tears down on `.cancelOnDeactivate(interactor: self)`.
public extension NSItemProvider {

  /// One-shot publisher that resolves to the in-memory representation for
  /// `typeIdentifier` (e.g. `UTType.image.identifier`, `UTType.movie.identifier`).
  /// Emits the `Data?` value the system returns (which can be `nil` even on
  /// success when the provider has no matching representation) and completes;
  /// fails with the underlying error on the failure path.
  ///
  /// - Note: the system may invoke the completion handler on a background queue.
  ///   The publisher does NOT append `.receive(on:)` — consumers that need a
  ///   main-thread sink either inject a `Scheduler` into their Interactor and
  ///   apply `.receive(on: scheduler)` at the call site, or absorb the hop
  ///   inside a Worker that re-emits a main-resident publisher. Keeping the
  ///   bridge thread-agnostic preserves the synchronous-flat property of the
  ///   subscriber's pipeline when the subscriber sits behind a Worker that
  ///   already owns the thread-crossing.
  static func loadDataPublisher(
    from provider: NSItemProvider,
    typeIdentifier: String
  ) -> AnyPublisher<Data?, Error> {
    Deferred {
      Future { promise in
        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
          if let error {
            promise(.failure(error))
            return
          }
          promise(.success(data))
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
