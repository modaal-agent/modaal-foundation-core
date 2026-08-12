// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// Composed external-facing contract — what `RootBuilder.build()` hands to
/// `SceneDelegate` via `RootLaunchHandle.appServices`. SceneDelegate stores
/// this as its only entry point into the RIB tree for URL and APNS dispatch.
///
/// Future cross-cutting handlers (user activities, shortcut items, scene
/// state restoration) should be added as new protocols composed into this
/// one — keep `RootLaunchHandle.appServices` typed as `AppServiceHandling`
/// so call sites never need to change.
///
/// sourcery: CreateMock
public protocol AppServiceHandling: AppServiceURLHandling, AppServiceNotificationHandling {
}
