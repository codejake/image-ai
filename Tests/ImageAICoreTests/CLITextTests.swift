import XCTest

@testable import ImageAICore

final class CLITextTests: XCTestCase {
  func testHelpIncludesCurrentVersion() {
    XCTAssertTrue(
      CLIText.usage.hasPrefix("image-ai \(CLIText.version)\n")
    )
  }

  func testHelpDocumentsEveryOptionAndPrivacyDefault() {
    XCTAssertTrue(CLIText.usage.contains("--use-cloud"))
    XCTAssertTrue(CLIText.usage.contains("--allow-cloud"))
    XCTAssertTrue(CLIText.usage.contains("--prompt <text>"))
    XCTAssertTrue(CLIText.usage.contains("--filename"))
    XCTAssertTrue(CLIText.usage.contains("-h, --help"))
    XCTAssertTrue(CLIText.usage.contains("--version"))
    XCTAssertTrue(CLIText.usage.contains("on-device by default"))
    XCTAssertTrue(CLIText.usage.contains("does not rename the source file"))
    XCTAssertTrue(
      CLIText.usage.contains("\(CLIParser.maximumPromptLength) characters")
    )
  }

  func testHelpDocumentsEverySupportedFormat() {
    for format in ["JPEG", "PNG", "HEIC", "WebP"] {
      XCTAssertTrue(
        CLIText.usage.contains(format),
        "Help should document \(format) support"
      )
    }
  }
}
