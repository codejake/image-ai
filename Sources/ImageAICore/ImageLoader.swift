import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct LoadedImage: @unchecked Sendable {
  public let image: CGImage
  public let sourceURL: URL

  public init(image: CGImage, sourceURL: URL) {
    self.image = image
    self.sourceURL = sourceURL
  }
}

public enum ImageLoadingError: Error, Equatable, LocalizedError {
  case fileNotFound(String)
  case notRegularFile(String)
  case unreadableFile(String)
  case unsupportedFormat(String)
  case corruptImage(String)

  public var errorDescription: String? {
    switch self {
    case .fileNotFound(let path):
      "file not found: \(path)"
    case .notRegularFile(let path):
      "not a regular file: \(path)"
    case .unreadableFile(let path):
      "file is not readable: \(path)"
    case .unsupportedFormat(let path):
      "unsupported image format (expected JPEG, PNG, HEIC, or WebP): \(path)"
    case .corruptImage(let path):
      "unable to decode image: \(path)"
    }
  }
}

public struct ImageLoader {
  public static let maximumDimension = 2_048

  private let fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func load(path: String) throws -> LoadedImage {
    let expandedPath = NSString(string: path).expandingTildeInPath
    let url = URL(fileURLWithPath: expandedPath).standardizedFileURL

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw ImageLoadingError.fileNotFound(path)
    }
    guard !isDirectory.boolValue else {
      throw ImageLoadingError.notRegularFile(path)
    }

    let values: URLResourceValues
    do {
      values = try url.resourceValues(forKeys: [.isRegularFileKey, .isReadableKey])
    } catch {
      throw ImageLoadingError.unreadableFile(path)
    }

    guard values.isRegularFile == true else {
      throw ImageLoadingError.notRegularFile(path)
    }
    guard values.isReadable == true else {
      throw ImageLoadingError.unreadableFile(path)
    }

    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
      if Self.hasSupportedExtension(url) {
        throw ImageLoadingError.corruptImage(path)
      }
      throw ImageLoadingError.unsupportedFormat(path)
    }
    guard let typeIdentifier = CGImageSourceGetType(source),
      let type = UTType(typeIdentifier as String),
      Self.isSupported(type)
    else {
      throw ImageLoadingError.unsupportedFormat(path)
    }

    guard let image = Self.normalizedFirstFrame(from: source) else {
      throw ImageLoadingError.corruptImage(path)
    }

    return LoadedImage(image: image, sourceURL: url)
  }

  private static func isSupported(_ type: UTType) -> Bool {
    type.conforms(to: .jpeg)
      || type.conforms(to: .png)
      || type.conforms(to: .heic)
      || type.conforms(to: .webP)
  }

  private static func hasSupportedExtension(_ url: URL) -> Bool {
    ["jpg", "jpeg", "png", "heic", "webp"].contains(
      url.pathExtension.lowercased()
    )
  }

  // ImageIO exposes animations as multiple image indexes. The product policy is
  // to describe only index zero, including for animated WebP files.
  static func normalizedFirstFrame(from source: CGImageSource) -> CGImage? {
    guard CGImageSourceGetCount(source) > 0 else {
      return nil
    }

    let thumbnailOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: Self.maximumDimension,
      kCGImageSourceShouldCacheImmediately: true,
    ]

    guard
      let decodedImage = CGImageSourceCreateThumbnailAtIndex(
        source,
        0,
        thumbnailOptions as CFDictionary
      )
    else {
      return nil
    }

    return normalizedImage(from: decodedImage)
  }

  private static func normalizedImage(from image: CGImage) -> CGImage? {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          | CGBitmapInfo.byteOrder32Big.rawValue
      )
    else {
      return nil
    }

    context.interpolationQuality = .high
    context.draw(
      image,
      in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
    )
    return context.makeImage()
  }
}
