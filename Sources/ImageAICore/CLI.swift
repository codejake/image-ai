import Foundation

public struct DescribeOptions: Equatable, Sendable {
  public let imagePath: String
  public let allowCloud: Bool
  public let filenameOutput: Bool

  public init(
    imagePath: String,
    allowCloud: Bool,
    filenameOutput: Bool = false
  ) {
    self.imagePath = imagePath
    self.allowCloud = allowCloud
    self.filenameOutput = filenameOutput
  }
}

public enum CLICommand: Equatable, Sendable {
  case help
  case version
  case describe(DescribeOptions)
}

public enum CLIParseError: Error, Equatable, LocalizedError {
  case missingImagePath
  case multipleImagePaths
  case unknownOption(String)

  public var errorDescription: String? {
    switch self {
    case .missingImagePath:
      "missing image path"
    case .multipleImagePaths:
      "expected exactly one image path"
    case .unknownOption(let option):
      "unknown option '\(option)'"
    }
  }
}

public enum CLIParser {
  public static func parse(_ arguments: [String]) throws -> CLICommand {
    if arguments.contains("-h") || arguments.contains("--help") {
      return .help
    }

    if arguments.contains("--version") {
      return .version
    }

    var allowCloud = false
    var filenameOutput = false
    var paths: [String] = []
    var parsesOptions = true

    for argument in arguments {
      if parsesOptions && argument == "--" {
        parsesOptions = false
      } else if parsesOptions && argument == "--allow-cloud" {
        allowCloud = true
      } else if parsesOptions && argument == "--filename" {
        filenameOutput = true
      } else if parsesOptions && argument.hasPrefix("-") {
        throw CLIParseError.unknownOption(argument)
      } else {
        paths.append(argument)
      }
    }

    guard !paths.isEmpty else {
      throw CLIParseError.missingImagePath
    }
    guard paths.count == 1 else {
      throw CLIParseError.multipleImagePaths
    }

    return .describe(
      DescribeOptions(
        imagePath: paths[0],
        allowCloud: allowCloud,
        filenameOutput: filenameOutput
      )
    )
  }
}

public enum CLIText {
  public static let version = "0.5.0"

  public static let usage = """
    Usage: image-ai [--allow-cloud] [--filename] <image-path>
           image-ai --help
           image-ai --version

    Describe one JPEG, PNG, HEIC, or WebP image using Apple Foundation Models.
    For animated WebP images, only the first frame is described.

    Options:
      --allow-cloud  Allow Private Cloud Compute only if the on-device model
                     is unavailable or encounters an infrastructure failure.
      --filename     Print a lowercase, hyphenated filename suggestion with the
                     original file extension.
      -h, --help     Show this help.
      --version      Show the program version.
    """
}
