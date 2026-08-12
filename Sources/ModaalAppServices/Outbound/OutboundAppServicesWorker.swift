// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import AppTrackingTransparency
import AVFoundation
import CombineRIBs
import Foundation
import UIKit
import UserNotifications

/// Everything the app asks *of* the system: opening URLs, the pasteboard,
/// haptics, the audio session, and the two authorization prompts.
///
/// A facade over seven iOS system singletons. Composition-root-owned,
/// `.start(self)`-ed alongside the other workers, and injected into features
/// via the narrow per-capability protocols rather than as a whole — a feature
/// that opens a URL takes `URLOpening`, so its test double implements one
/// method instead of eight.
///
/// Subclasses `Worker` for consistency with the rest of the app — every
/// cross-cutting service is a `Worker`. There is no current `didStart` /
/// `didStop` work, but the lifecycle hooks are available so future state
/// (e.g. caching `ATTrackingManager.trackingAuthorizationStatus`,
/// observing audio-session interruptions, debouncing repeated outbound
/// calls) plugs in here without restructuring.
public final class OutboundAppServicesWorker: Worker, OutboundAppServicesWorking {

  public override init() {
    super.init()
  }

  // MARK: - URLOpening

  public func open(_ url: URL) {
    // `UIApplication.shared.open(_:)` is documented as main-thread only.
    // Most callers (Interactor sinks on Combine `.receive(on: .main)`
    // pipelines, SwiftUI Button taps) already fire on main, so the fast
    // path is a direct call; off-main callers get an asynchronous hop so
    // we don't crash.
    if Thread.isMainThread {
      UIApplication.shared.open(url)
    } else {
      DispatchQueue.main.async {
        UIApplication.shared.open(url)
      }
    }
  }

  // MARK: - PasteboardReading

  public func readString() -> String? {
    // `UIPasteboard.general.string` reads are thread-safe.
    UIPasteboard.general.string
  }

  // MARK: - PasteboardWriting

  public func writeString(_ value: String) {
    // `UIPasteboard.general.string = …` is documented as safe from any
    // thread; the system pasteboard tolerates main-thread writes from
    // anywhere.
    UIPasteboard.general.string = value
  }

  // MARK: - HapticFeedbackProviding

  // `UIImpactFeedbackGenerator(style:).impactOccurred()` is documented as
  // main-thread only. Current call sites (SwiftUI Button-tap handlers,
  // Interactor pipelines on `.receive(on: .main)`) all fire on the main
  // thread; if off-main callers appear later, add a `Thread.isMainThread`
  // guard mirroring `open(_:)` above.

  public func impactLight() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  public func impactMedium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  public func impactSoft() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
  }

  // MARK: - AppTrackingAuthorizationRequesting

  public func requestTrackingAuthorizationIfNeeded() {
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
    ATTrackingManager.requestTrackingAuthorization { _ in }
  }

  // MARK: - AudioSessionConfiguring

  // `AVAudioSession.sharedInstance()` calls are thread-safe; failures
  // (other apps holding the session, route changes mid-call) are silently
  // ignored via `try?` per `AudioSessionConfiguring`'s best-effort contract.

  public func activatePlayback() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .moviePlayback)
    try? session.setActive(true, options: [.notifyOthersOnDeactivation])
  }

  public func deactivate() {
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  // MARK: - PushNotificationAuthorizationRequesting

  public func requestPushAuthorizationIfNeeded() {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .notDetermined:
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
          guard granted else { return }
          // `registerForRemoteNotifications()` is main-thread only and
          // drives the APNS device-token callback consumed by the inbound
          // `NotificationHandling` conformers via InboundAppServicesWorker.
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
        }
      case .authorized, .ephemeral, .provisional:
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      case .denied:
        break
      @unknown default:
        break
      }
    }
  }
}
