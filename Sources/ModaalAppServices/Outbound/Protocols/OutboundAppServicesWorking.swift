// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import Foundation

/// Composite of every outbound per-capability protocol the worker implements.
/// The composition root stores this; features depend on the narrow protocols
/// (`URLOpening`, `PasteboardReading`, …) instead, so a test stub implements
/// only the methods its subject actually calls.
///
/// Inherits from `Working` so the composition root can `.start(self)` it
/// uniformly with the other workers — every cross-cutting service in this
/// package is a `Worker`, one pattern, consistently applied.
///
/// To add a new outbound capability (e.g. `BiometricAuthRequesting`, share
/// sheet, screenshot capture):
///   1. Create a new narrow protocol next to `URLOpening` /
///      `PasteboardReading` / …, with `/// sourcery: CreateMock` and a
///      doc comment describing the threading and side-effect contract.
///   2. Add it to this composite's inheritance list.
///   3. Implement the methods in `OutboundAppServicesWorker`.
///   4. Expose it from the composition root as a narrow computed property.
///   5. Add a conformance assertion to `OutboundAppServicesWorkerConformanceSpec`.
///
/// Something the app *receives* rather than requests does not belong here —
/// it goes on `InboundAppServicesWorking`, which is where `AppLifecycleObserving`
/// lives.
///
/// sourcery: CreateMock
public protocol OutboundAppServicesWorking: Working,
                                            URLOpening,
                                            PasteboardReading,
                                            PasteboardWriting,
                                            HapticFeedbackProviding,
                                            AppTrackingAuthorizationRequesting,
                                            PushNotificationAuthorizationRequesting,
                                            AudioSessionConfiguring {
}
