import Foundation
import XCTest

@testable import ImageAICore

final class FilenameOutputTests: XCTestCase {
  func testFormatsDescriptionAndPreservesExtension() throws {
    let result = try FilenameOutput.format(
      description: "People playing soccer in a park.",
      sourceURL: URL(fileURLWithPath: "/tmp/photo.WEBP")
    )

    XCTAssertEqual(result, "people-playing-soccer-in-a-park.webp")
  }

  func testCollapsesPunctuationAndWhitespace() throws {
    let result = try FilenameOutput.format(
      description: "  Red car—near   water! ",
      sourceURL: URL(fileURLWithPath: "/tmp/photo.jpeg")
    )

    XCTAssertEqual(result, "red-car-near-water.jpeg")
  }

  func testPreservesUnicodeLettersAndDigits() throws {
    let result = try FilenameOutput.format(
      description: "Café with 2 tables",
      sourceURL: URL(fileURLWithPath: "/tmp/photo.png")
    )

    XCTAssertEqual(result, "café-with-2-tables.png")
  }

  func testAllowsExtensionlessInput() throws {
    let result = try FilenameOutput.format(
      description: "Blue ocean",
      sourceURL: URL(fileURLWithPath: "/tmp/photo")
    )

    XCTAssertEqual(result, "blue-ocean")
  }

  func testRejectsDescriptionWithoutFilenameCharacters() {
    XCTAssertThrowsError(
      try FilenameOutput.format(
        description: "—?!",
        sourceURL: URL(fileURLWithPath: "/tmp/photo.png")
      )
    ) { error in
      XCTAssertEqual(error as? FilenameOutputError, .emptyDescription)
    }
  }
}
