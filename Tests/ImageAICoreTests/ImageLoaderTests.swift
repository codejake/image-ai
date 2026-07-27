import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import ImageAICore

final class ImageLoaderTests: XCTestCase {
  private var temporaryDirectory: URL!

  override func setUpWithError() throws {
    temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
      at: temporaryDirectory,
      withIntermediateDirectories: true
    )
  }

  override func tearDownWithError() throws {
    if let temporaryDirectory {
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }
  }

  func testLoadsSupportedPNG() throws {
    let url = temporaryDirectory.appendingPathComponent("image.png")
    try writeImage(to: url, type: .png, width: 8, height: 4)

    let loaded = try ImageLoader().load(path: url.path)

    XCTAssertEqual(loaded.image.width, 8)
    XCTAssertEqual(loaded.image.height, 4)
    XCTAssertEqual(loaded.sourceURL, url.standardizedFileURL)
  }

  func testLoadsSupportedWebP() throws {
    let url = temporaryDirectory.appendingPathComponent("image.webp")
    let webP = Data(
      base64Encoded: "UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA"
    )
    XCTAssertNotNil(webP)
    try webP?.write(to: url)

    let loaded = try ImageLoader().load(path: url.path)

    XCTAssertEqual(loaded.image.width, 1)
    XCTAssertEqual(loaded.image.height, 1)
  }

  func testSelectsFirstFrameFromMultiFrameSource() throws {
    let url = temporaryDirectory.appendingPathComponent("animated.gif")
    guard
      let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.gif.identifier as CFString,
        2,
        nil
      )
    else {
      return XCTFail("Unable to create multi-frame test image")
    }

    CGImageDestinationAddImage(
      destination,
      try makeImage(red: 255, green: 0, blue: 0),
      nil
    )
    CGImageDestinationAddImage(
      destination,
      try makeImage(red: 0, green: 0, blue: 255),
      nil
    )
    XCTAssertTrue(CGImageDestinationFinalize(destination))

    guard
      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let firstFrame = ImageLoader.normalizedFirstFrame(from: source)
    else {
      return XCTFail("Unable to decode first frame")
    }

    let pixel = try rgbaPixel(from: firstFrame)
    XCTAssertGreaterThan(pixel.red, 200)
    XCTAssertLessThan(pixel.green, 80)
    XCTAssertLessThan(pixel.blue, 80)
  }

  func testDownsamplesLargeImage() throws {
    let url = temporaryDirectory.appendingPathComponent("large.jpg")
    try writeImage(to: url, type: .jpeg, width: 3_000, height: 1_500)

    let loaded = try ImageLoader().load(path: url.path)

    XCTAssertLessThanOrEqual(loaded.image.width, ImageLoader.maximumDimension)
    XCTAssertLessThanOrEqual(loaded.image.height, ImageLoader.maximumDimension)
  }

  func testRejectsMissingFile() {
    let path = temporaryDirectory.appendingPathComponent("missing.png").path

    XCTAssertThrowsError(try ImageLoader().load(path: path)) { error in
      XCTAssertEqual(
        error as? ImageLoadingError,
        .fileNotFound(path)
      )
    }
  }

  func testRejectsNonImage() throws {
    let url = temporaryDirectory.appendingPathComponent("notes.txt")
    try Data("not an image".utf8).write(to: url)

    XCTAssertThrowsError(try ImageLoader().load(path: url.path)) { error in
      XCTAssertEqual(
        error as? ImageLoadingError,
        .unsupportedFormat(url.path)
      )
    }
  }

  private func writeImage(
    to url: URL,
    type: UTType,
    width: Int,
    height: Int
  ) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    XCTAssertNotNil(context)
    context?.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
    context?.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let image = context?.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        type.identifier as CFString,
        1,
        nil
      )
    else {
      return XCTFail("Unable to create test image")
    }

    CGImageDestinationAddImage(destination, image, nil)
    XCTAssertTrue(CGImageDestinationFinalize(destination))
  }

  private func makeImage(
    red: UInt8,
    green: UInt8,
    blue: UInt8
  ) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
      let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      throw TestImageError.creationFailed
    }

    context.setFillColor(
      CGColor(
        red: CGFloat(red) / 255,
        green: CGFloat(green) / 255,
        blue: CGFloat(blue) / 255,
        alpha: 1
      )
    )
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))

    guard let image = context.makeImage() else {
      throw TestImageError.creationFailed
    }
    return image
  }

  private func rgbaPixel(from image: CGImage) throws -> (
    red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8
  ) {
    var pixel = [UInt8](repeating: 0, count: 4)
    let drewImage = pixel.withUnsafeMutableBytes { buffer in
      guard
        let address = buffer.baseAddress,
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(
          data: address,
          width: 1,
          height: 1,
          bitsPerComponent: 8,
          bytesPerRow: 4,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue
        )
      else {
        return false
      }

      context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      return true
    }

    guard drewImage else {
      throw TestImageError.creationFailed
    }
    return (pixel[0], pixel[1], pixel[2], pixel[3])
  }

  private enum TestImageError: Error {
    case creationFailed
  }
}
