// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

@testable import ModaalCombine
import Foundation
import Quick
import Nimble

final class CollectionFunctionalSpec: QuickSpec {
  static override func spec() {
    context("empty collection") {
      let sut = []
      it("any()") {
        expect(sut.any { _ in true }) == false
        expect(sut.any { _ in false }) == false
      }
      it("all()") {
        expect(sut.all { _ in true }) == false
        expect(sut.all { _ in false }) == false
      }
    } // context("empty collection")
    context("all elements match") {
      let sut = [0, 1, 2, 3]
      let predicate: (Int) -> Bool = { _ in true }
      it("any()") {
        expect(sut.any(predicate)) == true
      }
      it("all()") {
        expect(sut.all(predicate)) == true
      }
    } // context("all elements match")
    context("one element matches") {
      let sut = [0, 1, 2, 3]
      let predicate: (Int) -> Bool = { $0 == 0 }
      it("any()") {
        expect(sut.any(predicate)) == true
      }
      it("all()") {
        expect(sut.all(predicate)) == false
      }
    } // context("one element matches")
    context("all but one elements match") {
      let sut = [0, 1, 2, 3]
      let predicate: (Int) -> Bool = { $0 > 0 }
      it("any()") {
        expect(sut.any(predicate)) == true
      }
      it("all()") {
        expect(sut.all(predicate)) == false
      }
    } // context("all but one elements match")
    context("no elements match") {
      let sut = [0, 1, 2, 3]
      let predicate: (Int) -> Bool = { _ in false }
      it("any()") {
        expect(sut.any(predicate)) == false
      }
      it("all()") {
        expect(sut.all(predicate)) == false
      }
    } // context("no elements match")
  }
}
