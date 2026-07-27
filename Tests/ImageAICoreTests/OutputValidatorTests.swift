import XCTest

@testable import ImageAICore

final class OutputValidatorTests: XCTestCase {
  func testTrimsWhitespace() throws {
    XCTAssertEqual(
      try OutputValidator.validate("  Airplane over ocean  \n"),
      "Airplane over ocean"
    )
  }

  func testStripsMatchingQuotes() throws {
    XCTAssertEqual(
      try OutputValidator.validate("\"Airplane over ocean\""),
      "Airplane over ocean"
    )
    XCTAssertEqual(
      try OutputValidator.validate("“Airplane over ocean”"),
      "Airplane over ocean"
    )
  }

  func testRejectsEmptyOutput() {
    XCTAssertThrowsError(try OutputValidator.validate(" \n ")) { error in
      XCTAssertEqual(error as? OutputValidationError, .empty)
    }
    XCTAssertThrowsError(try OutputValidator.validate("\"\"")) { error in
      XCTAssertEqual(error as? OutputValidationError, .empty)
    }
  }

  func testRejectsMultipleLines() {
    XCTAssertThrowsError(
      try OutputValidator.validate("Airplane\nOver ocean")
    ) { error in
      XCTAssertEqual(error as? OutputValidationError, .multipleLines)
    }
  }

  func testRemovesAdjacentRepeatedPhrase() throws {
    XCTAssertEqual(
      try OutputValidator.validate(
        "People playing soccer playing soccer in a park"
      ),
      "People playing soccer in a park"
    )
  }

  func testRemovesAdjacentRepeatedWordIgnoringCase() throws {
    XCTAssertEqual(
      try OutputValidator.validate("Blue blue car"),
      "Blue car"
    )
  }

  func testPreservesMeaningfulNonAdjacentRepetition() throws {
    XCTAssertEqual(
      try OutputValidator.validate("Two dogs chasing another dog"),
      "Two dogs chasing another dog"
    )
  }
}
