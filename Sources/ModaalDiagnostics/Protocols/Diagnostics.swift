// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine
import CombineRIBs

public enum LogLevel: String {
  case info = "ℹ️"
  case warn = "⚠️"
  case error = "❗️"
  case fatal = "🛑"
}

/// sourcery: CreateMock
public protocol DiagnosticsLogging {
  func log(level: LogLevel, _ message: String)
  func exception(_ error: Error, userInfo: [String: Any]?, file: String, line: Int, function: String)
}

/// sourcery: CreateMock
public protocol DiagnosticsLogsObserving: DiagnosticsLogging {
  var logs: AnyPublisher<(level: LogLevel, message: String), Never> { get }
}

/// sourcery: CreateMock
public protocol Diagnostics: DiagnosticsLogsObserving {
  func setUserID(_ userID: String?)
  func setCustomValue(_ value: Any?, forKey key: String)
}

public extension DiagnosticsLogging {
  func info(_ message: String) { log(level: .info, message) }
  func warn(_ message: String) { log(level: .warn, message) }
  func error(_ message: String) { log(level: .error, message) }
  func fatal(_ message: String) { log(level: .fatal, message) }

  func exception(
    _ error: Error,
    userInfo: [String: Any]? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function) {
      exception(error, userInfo: userInfo, file: file, line: line, function: function)
    }
}
