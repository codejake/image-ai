import Foundation

public enum OutputValidationError: Error, Equatable, LocalizedError {
  case empty
  case multipleLines
  case controlCharacters

  public var errorDescription: String? {
    switch self {
    case .empty:
      "the model returned an empty description"
    case .multipleLines:
      "the model returned more than one line"
    case .controlCharacters:
      "the model returned unsupported control characters"
    }
  }
}

public enum OutputValidator {
  public static func validate(_ rawValue: String) throws -> String {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
      throw OutputValidationError.empty
    }
    guard !trimmed.contains(where: \.isNewline) else {
      throw OutputValidationError.multipleLines
    }
    guard
      !trimmed.unicodeScalars.contains(where: {
        CharacterSet.controlCharacters.contains($0)
      })
    else {
      throw OutputValidationError.controlCharacters
    }

    let normalized = removeAdjacentRepetitions(
      from: stripMatchingQuotes(from: trimmed)
    )
    guard !normalized.isEmpty else {
      throw OutputValidationError.empty
    }
    return normalized
  }

  private static func stripMatchingQuotes(from value: String) -> String {
    guard value.count >= 2,
      let first = value.first,
      let last = value.last,
      first == "\"" && last == "\""
        || first == "“" && last == "”"
        || first == "'" && last == "'"
    else {
      return value
    }

    return String(value.dropFirst().dropLast())
      .trimmingCharacters(in: .whitespaces)
  }

  private static func removeAdjacentRepetitions(from value: String) -> String {
    var words = value.split(whereSeparator: \.isWhitespace).map(String.init)
    guard words.count > 1 else {
      return value
    }

    var foundRepetition = true
    while foundRepetition {
      foundRepetition = false

      for length in stride(from: words.count / 2, through: 1, by: -1) {
        guard words.count >= length * 2 else {
          continue
        }

        for start in 0...(words.count - length * 2) {
          let first = words[start..<(start + length)].map(comparisonForm)
          let second = words[(start + length)..<(start + length * 2)]
            .map(comparisonForm)

          if first == second {
            words.removeSubrange((start + length)..<(start + length * 2))
            foundRepetition = true
            break
          }
        }

        if foundRepetition {
          break
        }
      }
    }

    return words.joined(separator: " ")
  }

  private static func comparisonForm(_ word: String) -> String {
    word.trimmingCharacters(in: .punctuationCharacters)
      .lowercased()
  }
}
