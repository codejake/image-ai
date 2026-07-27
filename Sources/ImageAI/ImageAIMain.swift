import Foundation
import ImageAICore

@main
struct ImageAIMain {
  private enum ExitCode {
    static let success: Int32 = 0
    static let usage: Int32 = 64
    static let dataError: Int32 = 65
    static let noInput: Int32 = 66
    static let unavailable: Int32 = 69
    static let software: Int32 = 70
  }

  static func main() async {
    do {
      let command = try CLIParser.parse(
        Array(CommandLine.arguments.dropFirst())
      )

      switch command {
      case .help:
        print(CLIText.usage)
      case .version:
        print("image-ai \(CLIText.version)")
      case .describe(let options):
        try await run(options)
      }
    } catch let error as CLIParseError {
      writeError(error.localizedDescription)
      writeError("Try 'image-ai --help' for usage.")
      exit(ExitCode.usage)
    } catch let error as ImageLoadingError {
      writeError(error.localizedDescription)
      exit(exitCode(for: error))
    } catch let error as DescriptionError {
      writeError(error.localizedDescription)
      exit(ExitCode.unavailable)
    } catch let error as OutputValidationError {
      writeError(error.localizedDescription)
      exit(ExitCode.software)
    } catch let error as FilenameOutputError {
      writeError(error.localizedDescription)
      exit(ExitCode.software)
    } catch {
      writeError("unexpected failure: \(error.localizedDescription)")
      exit(ExitCode.software)
    }
  }

  private static func run(_ options: DescribeOptions) async throws {
    let loadedImage = try ImageLoader().load(path: options.imagePath)
    let result = try await ImageDescriber().describe(
      loadedImage,
      allowCloud: options.allowCloud
    )

    if result.source == .privateCloudCompute {
      writeError("using Private Cloud Compute (--allow-cloud was specified)")
    }
    if options.filenameOutput {
      print(
        try FilenameOutput.format(
          description: result.text,
          sourceURL: loadedImage.sourceURL
        )
      )
    } else {
      print(result.text)
    }
  }

  private static func exitCode(for error: ImageLoadingError) -> Int32 {
    switch error {
    case .fileNotFound:
      ExitCode.noInput
    case .notRegularFile, .unreadableFile, .unsupportedFormat, .corruptImage:
      ExitCode.dataError
    }
  }

  private static func writeError(_ message: String) {
    let data = Data("image-ai: \(message)\n".utf8)
    FileHandle.standardError.write(data)
  }
}
