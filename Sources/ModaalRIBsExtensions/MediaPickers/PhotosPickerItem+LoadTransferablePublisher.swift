// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import PhotosUI
import SwiftUI

/// Combine bridge over `PhotosPickerItem.loadTransferable(type:)` —
/// `loadTransferable` is async-only in PhotosUI; this is the **irreducibly-async
/// carve-out** that wraps the underlying `Task { await … }` inside a
/// `Deferred { Future { promise in Task { … } } }` adapter, so consumer
/// Interactors see only a `Publisher` and never reach for `await` themselves.
///
/// Subscription semantics: the inner `Task` captures only `item`, `type`, and
/// the `promise` — never `self`, never an Interactor reference. The Task's
/// lifetime is bounded by the publisher's resolution (one promise call ends
/// it); when the subscription is cancelled before the Task completes, the
/// `promise` is dropped and the Task body's `await` proceeds to completion in
/// the background (the system handles cleanup of any in-flight transfer).
/// This is the standard cost of bridging an irreducibly-async API: structured
/// cancellation across the `await` is not propagated.
public extension PhotosPickerItem {

  /// One-shot publisher that resolves to `T?` for any `Transferable` type
  /// (`Data`, `Image`, custom `Transferable` conformers). Used by Interactors
  /// that receive a `PhotosPickerItem` from a `PhotosPicker` binding and need
  /// the loaded payload as a `Publisher` they can `.sink` on with
  /// `.cancelOnDeactivate(interactor: self)`.
  ///
  /// - Note: PhotosUI may dispatch the underlying transfer on a background
  ///   queue. The publisher does NOT append `.receive(on:)`; consumers that
  ///   need a main-thread sink either inject a `Scheduler` into their
  ///   Interactor and apply `.receive(on: scheduler)` at the call site, or
  ///   absorb the hop inside a Worker that re-emits a main-resident publisher.
  static func loadTransferablePublisher<T: Transferable>(
    from item: PhotosPickerItem,
    type: T.Type
  ) -> AnyPublisher<T?, Error> {
    Deferred {
      Future { promise in
        Task {
          do {
            let value = try await item.loadTransferable(type: type)
            promise(.success(value))
          } catch {
            promise(.failure(error))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
