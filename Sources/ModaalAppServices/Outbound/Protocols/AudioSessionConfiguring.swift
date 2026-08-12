// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import AVFoundation
import Foundation

/// Outbound audio-session configuration — activates the playback category for
/// media surfaces (video players, audio messages, in-app sound effects) and
/// deactivates it on dismissal so other apps' audio is restored. Wraps
/// `AVAudioSession.sharedInstance()` so Interactors and Views do not call the
/// singleton directly.
///
/// Interactors and Views MUST depend on `AudioSessionConfiguring` rather than
/// calling `AVAudioSession.sharedInstance().setCategory(...)` /
/// `.setActive(...)` directly. The composition root injects the narrow
/// protocol; the concrete `OutboundAppServicesWorker` does the singleton interaction
/// in one place.
///
/// Threading: both methods are safe to call from any thread —
/// `AVAudioSession` calls are thread-safe; failures (other apps holding the
/// session, route changes mid-call) are intentionally swallowed via `try?`,
/// matching iOS's "best-effort" media-session contract. Callers that need
/// hard error handling should add a `func activatePlayback() throws` variant
/// rather than promoting failure into the silent-success path here.
///
/// sourcery: CreateMock
public protocol AudioSessionConfiguring: AnyObject {
  /// Set the shared session to `.playback` / `.moviePlayback` and activate it
  /// so video and audio surfaces play through the speakers regardless of the
  /// silent-mode switch. Failures are silently ignored (best-effort).
  func activatePlayback()

  /// Deactivate the shared session with `.notifyOthersOnDeactivation` so
  /// other apps' audio (Music, Podcasts) resumes after our media surface
  /// dismisses. Failures are silently ignored (best-effort).
  func deactivate()
}
