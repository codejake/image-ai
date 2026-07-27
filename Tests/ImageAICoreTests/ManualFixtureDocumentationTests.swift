import Foundation
import XCTest

final class ManualFixtureDocumentationTests: XCTestCase {
  func testEveryManualImageFixtureIsDocumented() throws {
    let repositoryRoot = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let fixtureDirectory = repositoryRoot.appendingPathComponent(
      "Test-Images",
      isDirectory: true
    )
    let documentationURL = fixtureDirectory.appendingPathComponent("README.md")

    let supportedExtensions = Set(["jpg", "jpeg", "png", "heic", "webp"])
    let fixtureNames = try FileManager.default.contentsOfDirectory(
      at: fixtureDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
    .map(\.lastPathComponent)

    let documentation = try String(
      contentsOf: documentationURL,
      encoding: .utf8
    )
    let documentedNames =
      documentation
      .split(separator: "\n")
      .compactMap(Self.documentedFixtureName)

    XCTAssertEqual(
      Set(documentedNames),
      Set(fixtureNames),
      """
      Test-Images/README.md must contain one `## `filename`` section for every \
      non-hidden image fixture and no sections for deleted fixtures.
      """
    )
  }

  private static func documentedFixtureName(
    from line: Substring
  ) -> String? {
    let prefix = "## `"
    let suffix = "`"
    guard line.hasPrefix(prefix), line.hasSuffix(suffix) else {
      return nil
    }

    return String(line.dropFirst(prefix.count).dropLast(suffix.count))
  }
}
