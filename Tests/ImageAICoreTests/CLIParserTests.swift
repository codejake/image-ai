import XCTest

@testable import ImageAICore

final class CLIParserTests: XCTestCase {
  func testParsesSinglePath() throws {
    XCTAssertEqual(
      try CLIParser.parse(["photo.jpg"]),
      .describe(DescribeOptions(imagePath: "photo.jpg", useCloud: false))
    )
  }

  func testParsesCloudSelectionBeforeOrAfterPath() throws {
    let expected = CLICommand.describe(
      DescribeOptions(imagePath: "photo.jpg", useCloud: true)
    )

    XCTAssertEqual(
      try CLIParser.parse(["--use-cloud", "photo.jpg"]),
      expected
    )
    XCTAssertEqual(
      try CLIParser.parse(["photo.jpg", "--use-cloud"]),
      expected
    )
  }

  func testParsesCloudFallbackBeforeOrAfterPath() throws {
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

  func testUseCloudTakesPrecedenceWhenBothOptionsArePresent() throws {
    XCTAssertEqual(
      try CLIParser.parse([
        "--allow-cloud", "--use-cloud", "photo.jpg",
      ]),
      .describe(
        DescribeOptions(
          imagePath: "photo.jpg",
          useCloud: true,
          allowCloud: true
        )
      )
    )
  }

  func testDoubleDashAllowsPathBeginningWithDash() throws {
    XCTAssertEqual(
      try CLIParser.parse(["--", "-photo.jpg"]),
      .describe(DescribeOptions(imagePath: "-photo.jpg", useCloud: false))
    )
  }

  func testParsesFilenameOutputOption() throws {
    XCTAssertEqual(
      try CLIParser.parse(["--filename", "photo.WEBP"]),
      .describe(
        DescribeOptions(
          imagePath: "photo.WEBP",
          useCloud: false,
          filenameOutput: true
        )
      )
    )
  }

  func testParsesAdditionalPromptInBothForms() throws {
    let expected = CLICommand.describe(
      DescribeOptions(
        imagePath: "building.jpg",
        additionalPrompt: "Focus on the architecture"
      )
    )

    XCTAssertEqual(
      try CLIParser.parse([
        "--prompt", "Focus on the architecture", "building.jpg",
      ]),
      expected
    )
    XCTAssertEqual(
      try CLIParser.parse([
        "--prompt=Focus on the architecture", "building.jpg",
      ]),
      expected
    )
  }

  func testTrimsAdditionalPrompt() throws {
    XCTAssertEqual(
      try CLIParser.parse([
        "--prompt", "  Focus on the architecture  ", "building.jpg",
      ]),
      .describe(
        DescribeOptions(
          imagePath: "building.jpg",
          additionalPrompt: "Focus on the architecture"
        )
      )
    )
  }

  func testRejectsMissingPromptValue() {
    for arguments in [
      ["photo.jpg", "--prompt"],
      ["--prompt", "--filename", "photo.jpg"],
    ] {
      XCTAssertThrowsError(try CLIParser.parse(arguments)) { error in
        XCTAssertEqual(error as? CLIParseError, .missingPromptValue)
      }
    }
  }

  func testRejectsEmptyPrompt() {
    for arguments in [
      ["--prompt=", "photo.jpg"],
      ["--prompt", "   ", "photo.jpg"],
    ] {
      XCTAssertThrowsError(try CLIParser.parse(arguments)) { error in
        XCTAssertEqual(error as? CLIParseError, .emptyPrompt)
      }
    }
  }

  func testRejectsRepeatedPrompt() {
    XCTAssertThrowsError(
      try CLIParser.parse([
        "--prompt", "First", "--prompt=Second", "photo.jpg",
      ])
    ) { error in
      XCTAssertEqual(error as? CLIParseError, .duplicatePrompt)
    }
  }

  func testRejectsOversizedPrompt() {
    let prompt = String(repeating: "a", count: CLIParser.maximumPromptLength + 1)

    XCTAssertThrowsError(
      try CLIParser.parse(["--prompt", prompt, "photo.jpg"])
    ) { error in
      XCTAssertEqual(
        error as? CLIParseError,
        .promptTooLong(maximum: CLIParser.maximumPromptLength)
      )
    }
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
