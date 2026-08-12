# ModaalRIBsExtensions

UIKit helpers for apps built on [CombineRIBs](https://github.com/modaal-agent/CombineRIBs):
modal presentation owned by the router, navigation-controller conformance,
delegate proxies that turn UIKit callbacks into closures, and Combine bridges
for the media pickers.

```swift
.product(name: "ModaalRIBsExtensions", package: "modaal-foundation-core")
```

Depends on CombineRIBs and `ModaalSupport` (for `AnyActionHandler`). iOS only.

## Modal presentation

```swift
@discardableResult
func presentModal(
  _ child: ViewControllable,
  animated: Bool = true,
  configure: ((UISheetPresentationController) -> Void)? = nil,
  shouldDismiss: (() -> Bool)? = nil,
  didAttemptToDismiss: AnyActionHandler<Void>? = nil,
  onDismiss: AnyActionHandler<Void>
) -> ModalDismissToken

func dismissModal(_ token: ModalDismissToken, animated: Bool = true, completion: (() -> Void)? = nil)
```

An extension on `ViewableRouter`, so present and dismiss sit on the same object
and are symmetric. It is the alternative to hosting a child's
`UIViewController` inside a SwiftUI `.sheet` / `.fullScreenCover` / `.popover`,
where the binding and the router each believe they own the presentation.

- **`configure`** runs before `present(_:animated:)` with the presented
  controller's `UISheetPresentationController`, if it has one — detents,
  grabber, and so on.
- **`shouldDismiss`** is UIKit's synchronous veto on an interactive dismissal.
  Return `false` to block the swipe-down; UIKit then calls
  `didAttemptToDismiss`, which is where a "Discard changes?" alert goes.
- **`onDismiss`** fires only for **user-initiated** dismissal. UIKit does not
  call `presentationControllerDidDismiss` for a programmatic dismiss, so a
  router calling `dismissModal` must tear the child down on that path itself.
- **Keep the token.** `_ = router.presentModal(…)` compiles and leaves the
  router unable to dismiss the session. The token also anchors the delegate
  proxy: `UIPresentationController.delegate` is weak, so without it the proxy
  deallocates as `presentModal` returns and the dismissal callbacks never fire.
- `dismissModal` is idempotent. After an interactive dismissal or a previous
  call, the token is retired and further calls invoke `completion`
  synchronously and return, which keeps a chained-dismissal sequence intact.

**If the parent is already presenting something** — typically a SwiftUI sheet
whose binding just flipped to `false` while its hosting controller is still
attached — `presentModal` dismisses that first and presents from the
completion, because UIKit refuses a second concurrent presentation.

### Chained dismissal

When the presented controller has itself presented something (a router-owned
RIB that opened a system picker), dismissing both at once loses one of them:
UIKit ignores a `dismiss` issued while the receiver is already being dismissed
by another animation, and the outer controller leaks.

Sequence them:

1. Dismiss the inner one and wait for its `completion`.
2. Hop once more — `DispatchQueue.main.asyncAfter(deadline: .now() + 0.025)` —
   so UIKit has finished retiring the inner presentation.
3. Only then fire the callback that triggers the outer dismissal.

## `AnyViewControllable`

```swift
public final class AnyViewControllable: ViewControllable {
  public init(_ uiViewController: UIViewController)
}
```

Wraps a view controller the app did not build as a RIB — `PHPickerViewController`,
`UIImagePickerController`, `UIDocumentPickerViewController`, an alert — so it
can be handed to `presentModal`. It holds the controller strongly, so an inline
construction at the call site stays alive; the `ModalDismissToken` keeps the
wrapper alive for the session.

## `NavigationControllable`

```swift
public protocol NavigationControllable: ViewControllable {
  var uiNavigationController: UINavigationController { get }
  func push(_ viewController: ViewControllable, animated: Bool)
  func pop(animated: Bool)
  func present(_ viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
  func dismiss(animated: Bool, completion: (() -> ())?)
}
```

A default implementation is supplied for
`NavigationControllable where Self: UINavigationController`, so conformance is
one empty extension:

```swift
extension UINavigationController: NavigationControllable {}
```

Routers then push and pop through `ViewControllable` values without unwrapping
a `UIViewController` at each site.

## Delegate proxies

UIKit's picker and presentation delegates are protocols an object must conform
to; these three implement them and forward to closures, so a router can present
a picker without conforming to anything:

| Proxy | Wraps |
| --- | --- |
| `UIPresentationControllerDelegateProxy` | `UIAdaptivePresentationControllerDelegate` — dismissal veto, attempt, and completion |
| `UIImagePickerControllerStillImageDelegateProxy` | `UIImagePickerControllerDelegate` for a still image plus cancel |
| `UIImagePickerControllerVideoDelegateProxy` | the same for a movie URL |
| `PHPickerResultsHandlerProxy` | `PHPickerViewControllerDelegate` |

The handlers are `AnyActionHandler`s, so they hold their owner weakly (see
[ModaalSupport](ModaalSupport.md)). Each proxy is held by whatever presents it —
UIKit's delegate references are weak.

## Media-picker publishers

```swift
static func NSItemProvider.loadDataPublisher(from:typeIdentifier:) -> AnyPublisher<Data?, Error>
static func NSItemProvider.loadFileURLPublisher(from:typeIdentifier:subdirectory:) -> AnyPublisher<URL?, Error>
static func PhotosPickerItem.loadTransferablePublisher<T: Transferable>(from:type:) -> AnyPublisher<T?, Error>
```

Use the data form for images, the file form for movies and other large assets
where holding the bytes in memory is wasteful.

`Deferred { Future { … } }`, so the underlying load starts at subscribe time and
each subscription re-runs it. The closures capture only the provider, the type
identifier and the promise — no `self` — so cancelling the subscription
(`.cancelOnDeactivate(interactor:)`) tears it down cleanly.

Three things to know:

- A successful load can still yield `nil` when the provider holds no matching
  representation. The value is `Data?` / `URL?` / `T?` for that reason.
- **They do not `receive(on:)`.** The system may complete on a background
  queue. Apply the hop where you know which scheduler you want, rather than
  paying for one in every pipeline.
- **`loadFileURLPublisher` copies the file before emitting.** The URL the
  system hands back is valid only inside its completion handler — the file is
  gone once the closure returns. The bridge copies it to
  `FileManager.default.temporaryDirectory/<subdirectory>/<filename>`, replacing
  any file already at that path, and emits that URL. Deleting the copy is the
  caller's job; otherwise it lives until the OS purges the temp directory.

## `View.snapshot()`

```swift
public extension View {
  func snapshot() -> UIImage
}
```

Renders a SwiftUI view into a `UIImage` at its intrinsic content size, over a
clear background, via a `UIHostingController` and `UIGraphicsImageRenderer`.
Main-thread only, and the view must have a finite intrinsic size — a view that
expands to fill its parent renders at zero.
