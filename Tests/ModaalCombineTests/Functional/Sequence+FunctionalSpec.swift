// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

@testable import ModaalCombine
import Foundation
import Quick
import Nimble

final class SequenceFunctionalSpec: QuickSpec {
  static override func spec() {
    let sut: [Int?] = [0, 1, nil, nil, 2]
    describe("compact()") {
      it("removes nil elements") {
        expect(sut.compact()) == [0, 1, 2]
      }
    } // describe("compact()")
  }
}
