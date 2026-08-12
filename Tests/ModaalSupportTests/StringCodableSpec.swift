// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
@testable import ModaalSupport
import Quick
import Nimble

private enum Test: Hashable, Equatable {
  case aassa(value: String)
  case bbssa(value: Int)
}

extension Test: StringCodable {
  init(fromEncodedString string: String) throws {
    let split = string.components(separatedBy: CharacterSet(charactersIn: "()"))
    guard split.count >= 2 else { throw StringDecodableError.invalidFormatError(context: "Expected simple 'name(value)' format") }
    switch split[0] {
    case "aassa":
      self = .aassa(value: split[1])
    case "bbssa":
      guard let value = Int(split[1]) else { throw StringDecodableError.invalidFormatError(context: "bbssa: Expected Int value") }
      self = .bbssa(value: value)
    default:
      throw StringDecodableError.invalidFormatError(context: "uknown name")
    }
  }

  var asEncodedString: String {
    switch self {
    case .aassa(let value):
      return "aassa(\(value))"
    case .bbssa(let value):
      return "bbssa(\(value))"
    }
  }
}

final class StringCodableSpec: QuickSpec {
  override static func spec() {
    describe("Codable") {
      context("case 1") {
        let sut = Test.aassa(value: "value")
        it("encodes as a string") {
          expect(sut.asEncodedString) == "aassa(value)"
        }
        it("decodes from a string") {
          expect(try! Test(fromEncodedString: sut.asEncodedString)) == sut
        }
      } // context("case 1")
      context("case 2") {
        let sut = Test.bbssa(value: 12)
        it("encodes as a string") {
          expect(sut.asEncodedString) == "bbssa(12)"
        }
        it("decodes from a string") {
          expect(try! Test(fromEncodedString: sut.asEncodedString)) == sut
        }
      } // context("case 2")
    } // describe("Encodable")
  }
}
