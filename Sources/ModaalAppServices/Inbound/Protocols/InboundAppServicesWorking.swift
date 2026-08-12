// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import Foundation

/// Composed inbound contract — everything the app's composition root needs from
/// the inbound worker: start it as a `Worker`, hand it the scene and app
/// callbacks it dispatches (`AppServiceHandling`), and let features register
/// themselves as handlers (`AppServicesRegistering`) or subscribe to lifecycle
/// transitions (`AppLifecycleObserving`).
///
/// Features depend on one of the narrow protocols instead. A feature that
/// receives deep links takes `AppServicesRegistering`; a feature that pauses on
/// backgrounding takes `AppLifecycleObserving`; neither should see the whole
/// composite, which exists so the composition root has one type to store.
///
/// sourcery: CreateMock
public protocol InboundAppServicesWorking: Working,
                                          AppServicesRegistering,
                                          AppServiceHandling,
                                          AppLifecycleObserving {
}
