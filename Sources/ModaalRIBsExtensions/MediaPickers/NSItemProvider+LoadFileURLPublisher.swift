// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import Foundation

/// Combine bridge over `NSItemProvider.loadFileRepresentation(forTypeIdentifier:completionHandler:)`.
/// The system invokes the completion with a URL that is **only valid inside
/// the completion handler** — the file is removed as soon as the closure
/// returns. This bridge copies the file out to a caller-named subdirectory
/// of `FileManager.default.temporaryDirectory` so the resolved URL remains
/// readable after subscription.
///
/// Used by Interactors that consume `PHPickerResult`s for video / large-asset
/// flows where the in-memory `Data` form (see `loadDataPublisher(from:typeIdentifier:)`)
/// would be wasteful. The copied file lives under
/// `…/tmp/<subdirectory>/<original-filename>` until either the OS purges the
/// temp directory or the caller deletes it explicitly.
public extension NSItemProvider {

  /// One-shot publisher that resolves to a stable, caller-owned URL inside
  /// `FileManager.default.temporaryDirectory/<subdirectory>/`. The publisher
  /// emits `nil` only when the system returns success-with-nil-URL (no
  /// matching representation); failures from the system OR from the
  /// in-bridge copy are emitted as `.failure`.
  ///
  /// - Parameters:
  ///   - provider: source `NSItemProvider` (typically from `PHPickerResult.itemProvider`).
  ///   - typeIdentifier: the UTI to load (e.g. `UTType.movie.identifier`).
  ///   - subdirectory: a non-empty path component under `temporaryDirectory`
  ///     used to namespace this caller's copied files (e.g. `"PostMedia"`).
  ///
  /// - Note: the system may invoke the completion on a background queue.
  ///   The publisher does NOT append `.receive(on:)`; see the threading note
  ///   on `loadDataPublisher(from:typeIdentifier:)` for the rationale.
  static func loadFileURLPublisher(
    from provider: NSItemProvider,
    typeIdentifier: String,
    subdirectory: String
  ) -> AnyPublisher<URL?, Error> {
    Deferred {
      Future { promise in
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
          if let error {
            promise(.failure(error))
            return
          }
          guard let url else {
            promise(.success(nil))
            return
          }
          let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(subdirectory, isDirectory: true)
            .appendingPathComponent(url.lastPathComponent)
          do {
            try FileManager.default.createDirectory(
              at: dest.deletingLastPathComponent(),
              withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dest.path) {
              try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
            promise(.success(dest))
          } catch {
            promise(.failure(error))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}
