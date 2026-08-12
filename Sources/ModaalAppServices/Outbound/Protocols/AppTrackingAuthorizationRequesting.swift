// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import AppTrackingTransparency
import Foundation

/// Wraps Apple's App Tracking Transparency permission flow. The system
/// `ATTrackingManager.requestTrackingAuthorization` prompt fires exactly
/// once per install — only when status is `.notDetermined`; subsequent calls
/// return the existing status without re-prompting. This protocol is the
/// idempotent facade Interactors call into; the concrete worker
/// (`OutboundAppServicesWorker`) guards against re-prompting and is the only code in
/// the app that touches `ATTrackingManager` directly.
///
/// Interactors MUST depend on this protocol rather than calling
/// `ATTrackingManager.requestTrackingAuthorization` directly.
///
/// sourcery: CreateMock
public protocol AppTrackingAuthorizationRequesting: AnyObject {
  /// Shows the ATT prompt only if status is `.notDetermined`. No-ops
  /// otherwise. Fire-and-forget — the result is observable via
  /// `ATTrackingManager.trackingAuthorizationStatus` post-call (the
  /// composition root, or any service that needs the IDFA, can read the
  /// status after the prompt resolves).
  func requestTrackingAuthorizationIfNeeded()
}
