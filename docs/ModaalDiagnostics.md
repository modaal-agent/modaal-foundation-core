# ModaalDiagnostics

One logging and error-reporting seam, so feature code depends on a protocol
rather than on whichever crash reporter the app ships.

```swift
.product(name: "ModaalDiagnostics", package: "modaal-foundation-core")
```

Depends on [CombineRIBs](https://github.com/modaal-agent/CombineRIBs) for its
`Worker` base class. Imports no UIKit, but its watchOS support has not been
verified — see the README.

## The protocols

```swift
public protocol DiagnosticsLogging {
  func log(level: LogLevel, _ message: String)
  func exception(_ error: Error, userInfo: [String: Any]?, file: String, line: Int, function: String)
}

public protocol DiagnosticsLogsObserving: DiagnosticsLogging {
  var logs: AnyPublisher<(level: LogLevel, message: String), Never> { get }
}

public protocol Diagnostics: DiagnosticsLogsObserving {
  func setUserID(_ userID: String?)
  func setCustomValue(_ value: Any?, forKey key: String)
}
```

Depend on the narrowest one that does the job: a view model that only writes
logs takes `DiagnosticsLogging`, and a debug console that renders them takes
`DiagnosticsLogsObserving`.

`LogLevel` is `info`, `warn`, `error`, `fatal`. Its raw values are the emoji
used as the prefix in the formatted output.

A protocol extension supplies `info(_:)`, `warn(_:)`, `error(_:)` and
`fatal(_:)` shorthands, and an `exception(_:)` overload defaulting `userInfo`
to `nil` and `file`/`line`/`function` to the call site — so the usual call is
`diagnostics.exception(error)`.

The protocols carry `/// sourcery: CreateMock` annotations. They are inert
unless a consuming project runs [Sourcery](https://github.com/krzysztofzablocki/Sourcery)
with a template that reads them.

## `DiagnosticsWorker`

```swift
public final class DiagnosticsWorker: Worker, DiagnosticsWorking
public protocol DiagnosticsWorking: Working, Diagnostics {
  func setHooks(_ hooks: DiagnosticsWorkingHooks)
}
```

The implementation. It always logs locally and always republishes on `logs`;
what a host adds is a set of hooks:

```swift
public struct DiagnosticsWorkingHooks {
  public init(
    setUserID: ((String?) -> Void)? = nil,
    setCustomValue: ((Any?, String) -> Void)? = nil,
    log: ((String) -> Void)? = nil,
    record: ((Error, [String: Any]?) -> Void)? = nil
  )
}
```

Wire a crash reporter in one call, at composition root, without any feature
module importing that reporter:

```swift
worker.setHooks(
  DiagnosticsWorkingHooks(
    setUserID: { Crashlytics.crashlytics().setUserID($0) },
    setCustomValue: { Crashlytics.crashlytics().setCustomValue($0, forKey: $1) },
    log: { Crashlytics.crashlytics().log($0) },
    record: { error, info in Crashlytics.crashlytics().record(error: error, userInfo: info) }
  )
)
```

Every hook is optional, and each is called before — not instead of — the local
logging.

**Local output.** In `DEBUG` builds, `NSLog`. Otherwise `os_log`, with the level
mapped to `.default` / `.info` / `.error` / `.fault`. The subsystem is currently
the fixed string `modaal-app` and the category is `diagnostics`; making the
subsystem a consumer-supplied value is a change worth making, and it will be a
minor release when it happens.

**`exception`** merges the call-site `file`, `line` and `function` into the
`userInfo` it hands to the `record` hook, under the keys `_file_`, `_line_` and
`_function_`. A key the caller supplies wins over the injected one. The
formatted message is republished on `logs` at `.error`.

**Threading.** `DiagnosticsWorker` does no synchronization of its own: `log` and
`exception` publish on whichever thread called them, and `setHooks` is not
guarded against a concurrent `log`. Set the hooks once, during composition,
before anything logs.

## DEBUG-only helpers

```swift
#if DEBUG
public func isRunningTests() -> Bool
public func DEBUG_DISABLE_PRELOADING_TIMEOUT_ASSERTION() -> Bool
#endif
```

Both read the process environment — `XCTestBundlePath` for the first,
`DEBUG_DISABLE_PRELOADING_TIMEOUT_ASSERTION` for the second — and neither
exists in a release build. They are free functions rather than members, so they
are in scope wherever the module is imported.
