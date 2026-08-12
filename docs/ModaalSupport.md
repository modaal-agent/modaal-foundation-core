# ModaalSupport

Foundation-only helpers. No package dependencies; builds for iOS and watchOS.

```swift
.product(name: "ModaalSupport", package: "modaal-foundation-core")
```

## `StringCodable`

Two protocols for a type whose canonical serialized form is one string —
a deep-link route, a feature key, anything that has to survive a round trip
through a URL, a plist value or a single JSON string field.

```swift
public protocol StringEncodable {
  var asEncodedString: String { get throws }
}

public protocol StringDecodable {
  init(fromEncodedString string: String) throws
}

public typealias StringCodable = StringEncodable & StringDecodable
```

Conforming to `Codable` on top of them is free: `ModaalSupport` supplies
`encode(to:)` for `StringEncodable & Encodable` and `init(from:)` for
`StringDecodable & Decodable`, both going through a single-value container. So
a `StringCodable` type declared `Codable` encodes as a JSON string rather than
as an object, with no `CodingKeys` to write.

For the string itself there is a default `id(param, param)` format, in two
flavours:

| Method | Produces | Read back with |
| --- | --- | --- |
| `encodedDefault(id:params:)` | `route(a,b)` | `decodeDefault(_:)` |
| `encodedStringWithAdditionalEscaping(id:params:)` | `route(<<<a>>>,<<<b>>>)` | `decodeWithAdditionalEscaping(_:)` |

Use the escaping flavour when a parameter can itself contain a comma or a
parenthesis. The plain one splits on commas and trims whitespace, so a value
containing either does not survive the round trip.

Both decoders throw `StringDecodableError.invalidFormatError(context:)`, with
the context naming which part failed to scan.

```swift
enum Route: StringCodable, Codable {
  case profile(id: String)

  var asEncodedString: String {
    switch self {
    case .profile(let id): encodedDefault(id: "profile", params: [id])
    }
  }

  init(fromEncodedString string: String) throws {
    let (id, params) = try Self.decodeDefault(string)
    switch id {
    case "profile": self = .profile(id: params[0])
    default: throw StringDecodableError.invalidFormatError(context: "unknown id \(id)")
    }
  }
}
```

## `AnyActionHandler`

A type-erased callback that does not capture its owner strongly. The intended
use is passing an event out of a SwiftUI view to the object hosting it, where a
plain closure capturing `self` would create a cycle through the view's stored
property.

```swift
public struct AnyActionHandler<A> {
  public init<T: AnyObject>(_ weakOwner: T, closure: @escaping ActionHandler<T, A>.EventHandler)
  public init(_ handler: @escaping AnyEventHandler)

  public func invoke(_ arg: A)
  public func mapHandler<U>(_ transform: @escaping (U) -> A) -> AnyActionHandler<U>
}
```

The owning object is held weakly; once it is gone, `invoke` does nothing. The
closure receives the owner as its first argument, so it never needs to mention
`self`:

```swift
final class ProfileHost: UIHostingController<ProfileView> {
  var onSave: AnyActionHandler<String> {
    AnyActionHandler(self) { host, name in
      host.save(name)          // `host` is a strong reference, valid for the call
    }
  }
}
```

`invoke()` without an argument is available when `A == Void`.

`mapHandler(_:)` adapts a handler to a different argument type, which lets a
child view take `AnyActionHandler<ChildEvent>` while the owner deals in its own
event type.

`ActionHandler<T, A>` holds the weak reference internally. It is public only so
that its `EventHandler` typealias can appear in `AnyActionHandler`'s
initializer signature — its members are `fileprivate`, so always construct
through `AnyActionHandler`.

## `LocalizedStringResource.localized(_:)`

```swift
public func localized(_ locale: Locale) -> LocalizedStringResource
```

Returns a copy of the resource bound to an explicit locale, rather than to the
process locale. Use it where the language is data — a per-user preference, a
notification being composed for someone else's device — instead of the device
setting.
