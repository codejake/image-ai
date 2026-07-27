import Foundation

public struct DescribeOptions: Equatable, Sendable {
  public let imagePath: String
  public let useCloud: Bool
  public let allowCloud: Bool
  public let filenameOutput: Bool
  public let additionalPrompt: String?

  public init(
    imagePath: String,
    useCloud: Bool = false,
    allowCloud: Bool = false,
    filenameOutput: Bool = false,
    additionalPrompt: String? = nil
  ) {
    self.imagePath = imagePath
    self.useCloud = useCloud
    self.allowCloud = allowCloud
    self.filenameOutput = filenameOutput
    self.additionalPrompt = additionalPrompt
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
  case missingPromptValue
  case emptyPrompt
  case duplicatePrompt
  case promptTooLong(maximum: Int)
  case unknownOption(String)

  public var errorDescription: String? {
    switch self {
    case .missingImagePath:
      "missing image path"
    case .multipleImagePaths:
      "expected exactly one image path"
    case .missingPromptValue:
      "missing value for '--prompt'"
    case .emptyPrompt:
      "'--prompt' must not be empty"
    case .duplicatePrompt:
      "'--prompt' may only be specified once"
    case .promptTooLong(let maximum):
      "'--prompt' must be \(maximum) characters or fewer"
    case .unknownOption(let option):
      "unknown option '\(option)'"
    }
  }
}

public enum CLIParser {
  public static let maximumPromptLength = 1_000

  public static func parse(_ arguments: [String]) throws -> CLICommand {
    if arguments.contains("-h") || arguments.contains("--help") {
      return .help
    }

    if arguments.contains("--version") {
      return .version
    }

    var useCloud = false
    var allowCloud = false
    var filenameOutput = false
    var additionalPrompt: String?
    var paths: [String] = []
    var parsesOptions = true
    var index = 0

    while index < arguments.count {
      let argument = arguments[index]

      if parsesOptions && argument == "--" {
        parsesOptions = false
      } else if parsesOptions && argument == "--use-cloud" {
        useCloud = true
      } else if parsesOptions && argument == "--allow-cloud" {
        allowCloud = true
      } else if parsesOptions && argument == "--filename" {
        filenameOutput = true
      } else if parsesOptions && argument == "--prompt" {
        guard additionalPrompt == nil else {
          throw CLIParseError.duplicatePrompt
        }

        index += 1
        guard index < arguments.count,
          !arguments[index].hasPrefix("-")
        else {
          throw CLIParseError.missingPromptValue
        }
        additionalPrompt = try validatePrompt(arguments[index])
      } else if parsesOptions && argument.hasPrefix("--prompt=") {
        guard additionalPrompt == nil else {
          throw CLIParseError.duplicatePrompt
        }
        additionalPrompt = try validatePrompt(
          String(argument.dropFirst("--prompt=".count))
        )
      } else if parsesOptions && argument.hasPrefix("-") {
        throw CLIParseError.unknownOption(argument)
      } else {
        paths.append(argument)
      }

      index += 1
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
        useCloud: useCloud,
        allowCloud: allowCloud,
        filenameOutput: filenameOutput,
        additionalPrompt: additionalPrompt
      )
    )
  }

  private static func validatePrompt(_ value: String) throws -> String {
    let prompt = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !prompt.isEmpty else {
      throw CLIParseError.emptyPrompt
    }
    guard prompt.count <= maximumPromptLength else {
      throw CLIParseError.promptTooLong(maximum: maximumPromptLength)
    }
    return prompt
  }
}

public enum CLIText {
  public static let version = "0.6.0"

  public static var usage: String {
    """
    image-ai \(version)
    Describe an image with Apple Foundation Models.

    USAGE
      image-ai [options] <image-path>
      image-ai --help
      image-ai --version

    ARGUMENT
      <image-path>
          One readable local JPEG, PNG, HEIC, or WebP image. Relative paths are
          resolved from the current directory. For animated WebP files, only the
          first frame is described.

    OPTIONS
      --filename
          Print a filename suggestion instead of a sentence. The description is
          lowercased, punctuation is removed, words are joined with hyphens, and
          the source extension is retained. This does not rename the source file.

      --use-cloud
          Use Apple's Private Cloud Compute model instead of the on-device
          model. The image leaves the Mac when this option is used. PCC requires
          network access, eligibility, entitlement, and available quota.

      --allow-cloud
          Prefer the on-device model, but permit Private Cloud Compute as a
          fallback if local processing is unavailable or encounters an
          infrastructure failure. Safety refusals are not retried in the cloud.

      --prompt <text>
          Add guidance about what the description should emphasize. Core
          accuracy, safety, and output rules still apply. The prompt may contain
          at most \(CLIParser.maximumPromptLength) characters and may be specified once.

      -h, --help
          Print this help and exit.

      --version
          Print the program version and exit.

    EXAMPLES
      image-ai "Photos/family picnic.jpg"
      image-ai --filename screenshot.WEBP
      image-ai --prompt "Focus on the architecture" building.jpg
      image-ai --use-cloud photo.heic
      image-ai --allow-cloud photo.png

    PRIVACY
      Processing is on-device by default. No cloud request is permitted unless
      --use-cloud or --allow-cloud is specified. If both are specified,
      --use-cloud takes precedence. An additional prompt is sent with the image
      whenever Private Cloud Compute is used.
    """
  }
}
