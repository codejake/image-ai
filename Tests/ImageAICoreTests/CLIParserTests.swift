import XCTest

@testable import ImageAICore

final class CLIParserTests: XCTestCase {
  func testParsesSinglePath() throws {
    XCTAssertEqual(
      try CLIParser.parse(["photo.jpg"]),
      .describe(DescribeOptions(imagePath: "photo.jpg", allowCloud: false))
    )
  }

  func testParsesCloudOptInBeforeOrAfterPath() throws {
    let expected = CLICommand.describe(
      DescribeOptions(imagePath: "photo.jpg", allowCloud: true)
    )

    XCTAssertEqual(
      try CLIParser.parse(["--allow-cloud", "photo.jpg"]),
      expected
    )
    XCTAssertEqual(
      try CLIParser.parse(["photo.jpg", "--allow-cloud"]),
      expected
    )
  }

  func testDoubleDashAllowsPathBeginningWithDash() throws {
    XCTAssertEqual(
      try CLIParser.parse(["--", "-photo.jpg"]),
      .describe(DescribeOptions(imagePath: "-photo.jpg", allowCloud: false))
    )
  }

  func testParsesFilenameOutputOption() throws {
    XCTAssertEqual(
      try CLIParser.parse(["--filename", "photo.WEBP"]),
      .describe(
        DescribeOptions(
          imagePath: "photo.WEBP",
          allowCloud: false,
          filenameOutput: true
        )
      )
    )
  }

  func testHelpAndVersion() throws {
    XCTAssertEqual(try CLIParser.parse(["--help"]), .help)
    XCTAssertEqual(try CLIParser.parse(["-h"]), .help)
    XCTAssertEqual(try CLIParser.parse(["--version"]), .version)
  }

  func testRejectsMissingPath() {
    XCTAssertThrowsError(try CLIParser.parse([])) { error in
      XCTAssertEqual(error as? CLIParseError, .missingImagePath)
    }
  }

  func testRejectsMultiplePaths() {
    XCTAssertThrowsError(
      try CLIParser.parse(["one.jpg", "two.jpg"])
    ) { error in
      XCTAssertEqual(error as? CLIParseError, .multipleImagePaths)
    }
  }

  func testRejectsUnknownOption() {
    XCTAssertThrowsError(try CLIParser.parse(["--verbose", "photo.jpg"])) {
      error in
      XCTAssertEqual(error as? CLIParseError, .unknownOption("--verbose"))
    }
  }
}
