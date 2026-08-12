// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation
@testable import ModaalCombine
import Foundation
import Quick
import Nimble

final class SequenceDictionarySpec: QuickSpec {
  override static func spec() {
    let sut: [(String, Int)] = (0..<10).map { ("\($0)", $0) }
    it("converts sequence to dictionary") {
      expect(sut.dictionary()) == Dictionary(uniqueKeysWithValues: (0..<10).map { ("\($0)", $0) })
    }
  }
}
