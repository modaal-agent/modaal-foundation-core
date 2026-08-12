# ModaalAppServices

The layer between UIKit's app-level callbacks and feature code, split by
direction of travel:

- **Inbound** — the system hands the app a URL, a remote notification or a
  lifecycle transition, and one object routes it to whichever features want it.
- **Outbound** — a feature opens a URL, writes the pasteboard or fires a haptic
  through a protocol, so it does not reach for `UIApplication.shared` and can be
  tested without it.

```swift
.product(name: "ModaalAppServices", package: "modaal-foundation-core")
```

Depends on [CombineRIBs](https://github.com/modaal-agent/CombineRIBs): both
workers are `Worker` subclasses, started and stopped with the object that owns
them. iOS only.

The two workers are `InboundAppServicesWorker` and
`OutboundAppServicesWorker`, and the direction in the name is the whole
distinction: if the system initiates it, it is inbound; if your code initiates
it, it is outbound.

## Inbound: `InboundAppServicesWorker`

```swift
public protocol AppServicesRegistering:
  AppServicesURLHandlerRegistering, AppServicesAPNSHandlerRegistering {}

func registerURLHandler(_ handler: URLHandling, priority: AppServicePriority) -> AnyCancellable
func registerAPNSNotificationsHandler(_ handler: NotificationHandling, priority: AppServicePriority) -> AnyCancellable

var appLifecycle: AnyPublisher<AppLifecycleEvent, Never> { get }
```

Your composition root owns one `InboundAppServicesWorker`, exposes the narrow
`AppServicesRegistering` and `AppLifecycleObserving` to features, and forwards
the delegate callbacks it receives to `AppServiceHandling`:

```swift
// Scene delegate
func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
  appServices.openURLContexts(contexts.map { (url: $0.url, options: $0.options) })
}

// A feature, when it becomes active
appServices
  .registerURLHandler(self, priority: .default)
  .cancelOnDeactivate(interactor: self)
```

**URL and notification dispatch is chain-of-responsibility, ordered by
priority.** For a URL, the worker sorts handlers by descending priority and
calls `canHandleOpenUrl(_:)` on each; the first that returns `true` gets
`handleOpenUrl(_:)` and the rest are skipped. Remote notifications work the same
way through `canHandleRemoteNotification` / `handleRemoteNotification`.

`AppServicePriority` is `.high` (1000), `.default` (100), `.fallback` (0) —
a handler that owns one specific scheme takes `.high`, a feature deeplink takes
`.default`, a catch-all logger takes `.fallback`.

**`canHandleOpenUrl(_:)` must be a pure predicate.** The worker asks several
handlers before finding a match, so a side effect there runs for URLs the
handler does not end up processing.

**Device-token registration is broadcast, not claimed.**
`appDidRegisterForRemoteNotifications(deviceToken:)` goes to every registered
handler.

**Lifecycle is a publisher, not a registration.** Every subscriber gets every
event, so there is nothing to arbitrate and no priority to declare — see
[`AppLifecycleObserving`](#applifecycleobserving) below.

**The worker retains handlers strongly.** The returned `AnyCancellable` is the
only deregistration; bind it to the registering object's lifetime. Registering
the same handler twice updates its priority rather than adding a second entry.

**Threading.** Registration and dispatch are guarded by an `NSRecursiveLock`.
The handler list is copied under the lock and the handlers are then called
outside it, so a handler that registers or deregisters during dispatch does not
deadlock — but it also does not affect the dispatch already in flight.

### Protocols

| Protocol | Implemented by | Called by |
| --- | --- | --- |
| `URLHandling` | a feature | the worker |
| `NotificationHandling` | a feature | the worker |
| `AppServicesRegistering` | the worker | features |
| `AppLifecycleObserving` | the worker | features |
| `AppServiceURLHandling`, `AppServiceNotificationHandling` (composed as `AppServiceHandling`) | the worker, usually re-exposed by the composition root | the scene delegate |

`InboundAppServicesWorking` composes all of them and is what the composition
root stores.

Keep the composition root's outward-facing property typed as
`AppServiceHandling`. Adding user activities or shortcut items later is then a
new protocol composed into it, and no call site changes.

### `AppLifecycleObserving`

```swift
public enum AppLifecycleEvent: Equatable, Sendable {
  case didBecomeActive, willResignActive, didEnterBackground, willEnterForeground
}
```

It exists as a protocol because `NotificationCenter.default` is a singleton, and
a feature subscribing to it directly cannot be tested without posting real
`UIApplication` notifications into the test process, where they reach every
other test doing the same thing.

`willResignActive` fires for interruptions that do not background the app — a
call, the Control Centre pull-down — so anything that must pause under a
notification shade listens for it rather than for `didEnterBackground`.

The publisher delivers on the main thread, because that is where UIKit posts,
and deliberately does not `receive(on:)`: the extra hop would land
`willResignActive` a runloop turn late, after the system has taken its snapshot.

For tests, construct the worker with your own center and post into it:

```swift
let center = NotificationCenter()
let worker = InboundAppServicesWorker(notificationCenter: center)
center.post(name: UIApplication.willResignActiveNotification, object: nil)
```

## Outbound: `OutboundAppServicesWorker`

One protocol per capability, all implemented by a single worker:

| Protocol | Methods |
| --- | --- |
| `URLOpening` | `open(_ url: URL)` |
| `PasteboardReading` | `readString() -> String?` |
| `PasteboardWriting` | `writeString(_:)` |
| `HapticFeedbackProviding` | `impactLight()`, `impactMedium()`, `impactSoft()` |
| `AppTrackingAuthorizationRequesting` | `requestTrackingAuthorizationIfNeeded()` |
| `PushNotificationAuthorizationRequesting` | `requestPushAuthorizationIfNeeded()` |
| `AudioSessionConfiguring` | `activatePlayback()`, `deactivate()` |

Features depend on the one they need, so a test double implements one or two
methods rather than seven. `OutboundAppServicesWorking` composes all of them and
is what the composition root stores.

```swift
final class ShareInteractor {
  private let urlOpener: URLOpening        // not UIApplication
  private let pasteboard: PasteboardWriting
}
```

### Adding a capability

1. Write the narrow protocol next to the others, with a doc comment stating its
   threading and side-effect contract.
2. Add it to `OutboundAppServicesWorking`'s inheritance list.
3. Implement it in `OutboundAppServicesWorker`.
4. Expose it from your composition root as a narrow property.
5. Add the conformance to `OutboundAppServicesWorkerConformanceSpec`.

Something the app *receives* rather than requests goes on the inbound side
instead.

### Threading of the outbound calls

- `open(_:)` calls `UIApplication.shared.open` directly when already on the main
  thread and hops asynchronously otherwise.
- Pasteboard reads and writes are safe from any thread.
- The haptics calls are **main-thread only** and do not check. Call them from
  the main thread.
- Under complete concurrency checking, the haptics and UIKit calls in this
  module account for most of the package's remaining warnings; see the README.

## `DefaultHapticFeedback` and the SwiftUI environment

`DefaultHapticFeedback` implements `HapticFeedbackProviding` on its own, for
surfaces that have no worker in reach. The module also adds a
`\.hapticFeedback` environment key so a SwiftUI view can take the capability
without an initializer parameter:

```swift
@Environment(\.hapticFeedback) private var haptics
```
