// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

public extension StringEncodable where Self: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(asEncodedString)
  }
}

public extension StringDecodable where Self: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    try self.init(fromEncodedString: string)
  }
}

public enum StringDecodableError: Error {
  case invalidFormatError(context: String)
}
