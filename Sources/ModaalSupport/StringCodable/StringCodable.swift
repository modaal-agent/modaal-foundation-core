// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

public protocol StringEncodable {
  var asEncodedString: String { get throws }
}

public protocol StringDecodable {
  init(fromEncodedString string: String) throws
}

public typealias StringCodable = StringEncodable & StringDecodable

public extension StringEncodable {
  /// Encode into string
  func encodedDefault(id: String, params: [String?]) -> String {
    let params = params.map { $0 ?? "" }.joined(separator: ",")
    return "\(id)(\(params))"
  }

  /// Encode string, additionally enclosing each parameter into a `<<</>>>` pattern.
  func encodedStringWithAdditionalEscaping(id: String, params: [String?]) -> String {
    let params = params.map { $0 ?? "" }.joined(separator: ">>>,<<<")
    return "\(id)(\(!params.isEmpty ? "<<<\(params)>>>" : ""))"
  }
}

public extension StringDecodable {
  /// Decode string, where each parameter is additionally enclosed into a `<<</>>>` pattern.
  static func decodeWithAdditionalEscaping(_ string: String) throws -> (id: String, params: [String]) {
    let scanner = Scanner(string: string)

    guard
      let id = scanner.scanUpToString("("),
      !id.isEmpty,
      let _ = scanner.scanString("(")
    else {
      throw StringDecodableError.invalidFormatError(context: "Can't read id")
    }

    var params: [String] = []
    while true {
      guard
        let _ = scanner.scanString("<<<"),
        let param = scanner.scanUpToString(">>>"),
        let _ = scanner.scanString(">>>")
      else {
        break
      }

      params.append(param)
      _ = scanner.scanString(",")
    }

    return (id, params)
  }
}

public extension StringDecodable {
  /// Decode simple format `id(param[, param]*)`
  static func decodeDefault(_ string: String) throws -> (id: String, params: [String]) {
    let scanner = Scanner(string: string)
    scanner.charactersToBeSkipped = nil

    guard let id = scanner.scanUpToString("("),
          !id.isEmpty,
          let _ = scanner.scanString("(") else {
      throw StringDecodableError.invalidFormatError(context: "Can't read id")
    }

    let paramsString = scanner.scanUpToString(")") ?? "" // `scanUpToString(")")` returns `nil` if the string is empty
    guard let _ = scanner.scanString(")") else {
      throw StringDecodableError.invalidFormatError(context: "Can't read parameters")
    }

    let params = paramsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    return (id, params)
  }
}
