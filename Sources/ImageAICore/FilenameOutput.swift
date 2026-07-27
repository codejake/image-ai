import Foundation

public enum FilenameOutputError: Error, Equatable, LocalizedError {
  case emptyDescription

  public var errorDescription: String? {
    switch self {
    case .emptyDescription:
      "the description cannot be converted to a filename"
    }
  }
}

public enum FilenameOutput {
  public static func format(
    description: String,
    sourceURL: URL
  ) throws -> String {
    var components: [String] = []
    var currentComponent = ""

    for character in description.lowercased() {
      if character.isLetter || character.isNumber {
        currentComponent.append(character)
      } else if !currentComponent.isEmpty {
        components.append(currentComponent)
        currentComponent = ""
      }
    }

    if !currentComponent.isEmpty {
      components.append(currentComponent)
    }

    guard !components.isEmpty else {
      throw FilenameOutputError.emptyDescription
    }

    let basename = components.joined(separator: "-")
    let fileExtension = sourceURL.pathExtension.lowercased()
    guard !fileExtension.isEmpty else {
      return basename
    }

    return "\(basename).\(fileExtension)"
  }
}
