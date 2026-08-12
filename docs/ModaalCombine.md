# ModaalCombine

Combine operators and sequence helpers. No package dependencies; builds for iOS
and watchOS.

```swift
.product(name: "ModaalCombine", package: "modaal-foundation-core")
```

## `Publisher.skip(while:)`

```swift
public func skip(while predicate: @escaping (Output) -> Bool) -> AnyPublisher<Output, Failure>
```

Drops leading values while `predicate` returns `true`, then forwards
everything — including later values the predicate would have rejected. This is
`drop(while:)`'s behaviour; the operator exists because it erases to
`AnyPublisher` and reads the same as the other `skip`-named operators in a
chain.

```swift
// Ignore the initial `nil` a CurrentValueSubject starts with, then take
// every value, including a later nil.
subject.skip { $0 == nil }
```

## `CurrentValueSubject.updateValue`

```swift
public func updateValue(_ update: (Output) -> (Output))
public func updateValue(_ update: (inout Output) -> ())
```

Read-modify-write in one call, so a caller mutating one field of a struct value
does not spell out `var v = subject.value; v.x = …; subject.value = v`.

```swift
state.updateValue { $0.isLoading = true }
```

Not atomic. Two concurrent callers can still lose an update; if that matters,
serialize the calls yourself.

## Sequence and Collection helpers

```swift
public extension Sequence where Element: OptionalType {
  func compact() -> [Element.Wrapped]
}

public extension Sequence where Element: Sequence {
  func flatten() -> [Element.Element]
}

public extension Sequence {
  func dictionary<Key, Value>() -> [Key: Value] where Element == (Key, Value)
  func dictionary<Key, Value>(uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key: Value] where Element == (Key, Value)
}

public extension Collection {
  func any(_ predicate: (Element) -> Bool) -> Bool
  func all(_ predicate: (Element) -> Bool) -> Bool
}
```

- `compact()` drops the nils, the way `compactMap { $0 }` does, without the
  closure. It reaches optionals through `OptionalType`, a protocol declaring
  only `flatMap`, which `Optional` conforms to; that is what makes
  "a sequence of optionals" expressible as a constraint at all.
- **`dictionary()` traps on a duplicate key.** It is
  `Dictionary(uniqueKeysWithValues:)`, so use it only where the keys are known
  distinct; reach for the `uniquingKeysWith:` overload
  (`Dictionary.init(_:uniquingKeysWith:)`) whenever they might not be.
- **`all` returns `false` for an empty collection.** The standard library's
  `allSatisfy` returns `true` there, vacuously. This is deliberate — the calls
  reading "all of these are ready" want an empty list to mean "no" — but it is
  the one place where swapping `all` for `allSatisfy` changes behaviour.

## `OptionalType`

```swift
public protocol OptionalType {
  associatedtype Wrapped
  func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> U?
}

extension Optional: OptionalType {}
```

Public so that consumers can write their own `where Element: OptionalType`
constraints, not because anything else is expected to conform.
