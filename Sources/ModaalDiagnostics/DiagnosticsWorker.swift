// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import CombineRIBs
import Foundation
import os

public struct DiagnosticsWorkingHooks {
  let setUserID: ((_ userID: String?) -> ())?
  let setCustomValue: ((_ value: Any?, _ key: String) -> ())?
  let log: ((_ message: String) -> ())?
  let record: ((_ error: Error, _ userInfo: [String: Any]?) -> ())?

  public init(
    setUserID: ((_: String?) -> Void)? = nil,
    setCustomValue: ((_: Any?, _: String) -> Void)? = nil,
    log: ((_: String) -> Void)? = nil,
    record: ((_: Error, _: [String : Any]?) -> Void)? = nil,
  ) {
    self.setUserID = setUserID
    self.setCustomValue = setCustomValue
    self.log = log
    self.record = record
  }
}

/// sourcery: CreateMock
public protocol DiagnosticsWorking: Working, Diagnostics {
  func setHooks(_ hooks: DiagnosticsWorkingHooks)
}

public final class DiagnosticsWorker: Worker, DiagnosticsWorking {

  var hooks: DiagnosticsWorkingHooks?

  private let _logs = PassthroughSubject<(level: LogLevel, message: String), Never>()

  override public init() {
    super.init()
  }

  // MARK: - DiagnosticsWorking

  public func setHooks(_ hooks: DiagnosticsWorkingHooks) {
    self.hooks = hooks
  }

  // MARK: - DiagnosticsLogging

  public func log(level: LogLevel, _ message: String) {
    let string = "\(level.rawValue): \(message)"
    hooks?.log?(string)
    #if DEBUG
    NSLog(string)
    #else
    let log = OSLog(subsystem: "modaal-app", category: "diagnostics")
    os_log("%{public}s", log: log, type: level.osLogType, string)
    #endif
    _logs.send((level: level, message: message))
  }

  public func exception(_ error: Error, userInfo: [String: Any]?, file: String, line: Int, function: String) {
    var mergedInfo: [String: Any] = [
      "_file_": file,
      "_line_": line,
      "_function_": function
    ]
    if let userInfo {
      mergedInfo.merge(userInfo, uniquingKeysWith: { a, _ in a })
    }

    hooks?.record?(error, mergedInfo)
    let string = "\(LogLevel.error.rawValue) \(error.localizedDescription) (\(mergedInfo)))"
    #if DEBUG
    NSLog(string)
    #endif
    _logs.send((level: .error, message: string))
  }

  // MARK: - DiagnosticsLogsObserving

  public var logs: AnyPublisher<(level: LogLevel, message: String), Never> {
    _logs.eraseToAnyPublisher()
  }

  // MARK: - Diagnostics

  public func setUserID(_ userID: String?) {
    hooks?.setUserID?(userID)
  }

  public func setCustomValue(_ value: Any?, forKey key: String) {
    hooks?.setCustomValue?(value, key)
  }
}

#if DEBUG
public func isRunningTests() -> Bool {
  return ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
}
public func DEBUG_DISABLE_PRELOADING_TIMEOUT_ASSERTION() -> Bool {
  Bool(ProcessInfo.processInfo.environment["DEBUG_DISABLE_PRELOADING_TIMEOUT_ASSERTION"] ?? "") == true
}
#endif

private extension LogLevel {
  var osLogType: OSLogType {
    switch self {
    case .info:
      return .default
    case .warn:
      return .info
    case .error:
      return .error
    case .fatal:
      return .fault
    }
  }
}
