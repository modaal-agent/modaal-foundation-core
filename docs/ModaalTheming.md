# ModaalTheming

A theme engine for UIKit and SwiftUI. Your app supplies the catalog — which
colors, fonts, images and gradients each theme has — and this module resolves an
asset key to a concrete value for the current theme and appearance, and
remembers the user's choice.

```swift
.product(name: "ModaalTheming", package: "modaal-foundation-core")
```

No package dependencies, and it does not get any: a project that wants a theme
engine should not have to resolve anything else to get one. iOS only — it
imports UIKit and SwiftUI.

Derived from [SwiftTheming](https://github.com/dscyrescotti/SwiftTheming) (MIT);
see [NOTICE](../NOTICE).

## The shape

| Type | Who writes it |
| --- | --- |
| `Theme` | the engine — a `Codable`, `Sendable` struct wrapping one `String` key |
| `Themed` | the engine — an `open class` you subclass, once per theme |
| `Assetable` | the engine — the protocol your `Themed` subclass conforms to |
| `ColorAssetable` / `FontAssetable` / `ImageAssetable` / `GradientAssetable` | you — marker protocols for your asset key enums |
| `ColorSet` / `FontSet` / `ImageSet` / `GradientSet` | the engine — an `Appearance` plus, for fonts, metrics |
| `ThemeProvider` | the engine — resolves and persists |

`Appearance<T>` is how one asset covers light and dark:

```swift
public enum Appearance<T> {
  case `static`(T)                              // same value everywhere
  case dynamic((UITraitCollection) -> T)        // computed from traits
  case auto(light: T, dark: T)                  // one of two
}
```

For `UIColor`, `.dynamic` and `.auto` resolve to a **dynamic `UIColor`** when
the preferred appearance is `.system`, so a color already handed to a view keeps
following the system setting. For every other type the value is resolved once,
at the call.

## Wiring it up

```swift
import ModaalTheming
import UIKit

// 1. Asset keys — plain enums conforming to the marker protocols.
enum ColorAsset: ColorAssetable { case background, accent }
enum FontAsset: FontAssetable { case title }

// 2. One `Themed` subclass per theme, declaring the catalog.
//    Families you do not use are declared as `EmptyAsset`, which supplies a
//    trapping default implementation you never call.
final class DefaultThemed: Themed, Assetable {
  typealias _ColorAsset = ColorAsset
  typealias _FontAsset = FontAsset
  typealias _ImageAsset = EmptyAsset
  typealias _GradientAsset = EmptyAsset

  func colorSet(for asset: ColorAsset) -> ColorSet {
    switch asset {
    case .background: ColorSet(.auto(light: .white, dark: .black))
    case .accent:     ColorSet(.static(.systemBlue))
    }
  }

  func fontSet(for asset: FontAsset) -> FontSet {
    switch asset {
    case .title:
      FontSet(
        .static(.systemFont(ofSize: 28, weight: .bold)),
        fontMetrics: FontMetrics(pointSize: 28, lineHeight: 34, letterSpacing: 0.5.pct)
      )
    }
  }
}

// 3. Name the themes and map each key to its `Themed`.
extension Theme {
  static let `default` = Theme(key: "default")
}

extension Theme: Themeable {
  public func themed() -> Themed {
    switch self {
    case .default: DefaultThemed()
    default:       DefaultThemed()
    }
  }
}

// 4. One provider, at composition root.
let themeProvider = ThemeProvider(
  persistentStorage: ThemePersistentStorage(),
  defaultTheme: .default,
  defaultPreferredAppearance: .system
)
```

**Step 3 is not optional.** `Theme` resolves a catalog by casting itself to
`Themeable`, so an app that never writes that conformance traps at the first
lookup rather than failing to compile. The same is true of an asset key handed
to the wrong family: `Assetable`'s bridge force-casts, so passing a
`ColorAsset` where the theme declared a different `_ColorAsset` traps.

An app that reads the theme through the SwiftUI environment (next section)
also registers its default theme, beside the `Themeable` conformance and
under the same contract class — a declaration the engine resolves by cast:

```swift
extension ThemeDefaults: ThemeDefaulting {
  public func defaultTheme() -> Theme { .default }
}
```

## The SwiftUI environment

A view reads `@Environment(\.theme)` and calls `theme.color(.token)`; no view
takes a theming parameter and no view model carries one. A SwiftUI
environment value does not cross a UIKit boundary, so the provider is
published once per SwiftUI tree, at the hosting root: subclass
`ThemedHostingController` and hand it the provider, or wrap a single tree in
`ThemeScope(provider) { ... }`. Assign hosted content through
`themedRootView` — plain `rootView` assignment is a compile error by design.

Trees nobody published to — Xcode previews, most test hosts — resolve the
environment's default, which is a `ThemeProvider` over the persisted choice
falling back to the registered `ThemeDefaulting` conformance above. The
module names no concrete theme; previews render the app's own default
palette because the conformance is linked into the binary, with no startup
code involved. A test target that renders unhosted trees declares its own
test-local conformance.

## Reading assets

```swift
let color  = themeProvider.color(for: ColorAsset.accent)
let (font, metrics) = themeProvider.font(for: FontAsset.title)
```

Every accessor has four overloads — the full one takes both a
`preferredAppearance:` and an `on theme:` override, and protocol extensions
supply the three shorter forms. Passing an override resolves against that theme
or appearance without changing the provider's state, which is what a theme
picker's preview swatches need.

`FontMetrics` carries `pointSize`, an optional `lineHeight`, and a
`LetterSpacing` that is either `.px` or `.pct`; `toPoints(_:)` converts it
against a point size. `0.5.pct` and `1.2.px` are shorthands on float literals.

## Changing and persisting the theme

```swift
public protocol ThemeProvidingUpdating: ThemeProviding {
  func setTheme(with theme: Theme)
  func setPreferredAppearance(with appearance: PreferredAppearance)
}
```

Both are no-ops when the value is unchanged, and both write through to storage.

`ThemePersistentStorage` is the supplied implementation: JSON in
`UserDefaults.standard`, under the keys `theming.theme.key` and
`theming.preferredAppearance.key`. Substitute your own by conforming to
`ThemeProviderPersisting` — an app group's defaults, or an in-memory double in
tests.

**`ThemeProvider` is not observable.** `setTheme(with:)` updates state and
storage; views that read the provider through the SwiftUI environment do not
re-render until something else invalidates them. Drive the refresh yourself —
publish the change from your own state object, or reload the view hierarchy at
the point where the theme is changed.

`ThemeProviding` is `AnyObject`-constrained: a provider is identified by
reference, so a struct conformer would be boxed anew on each read and
`ObjectIdentifier` comparisons against it would not hold.

## Threading

`ThemeProvider` is not synchronized and its stored properties are read and
written directly. Use it from the main actor.
