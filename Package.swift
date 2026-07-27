// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "image-ai",
  platforms: [
    .macOS("27.0")
  ],
  products: [
    .executable(name: "image-ai", targets: ["ImageAI"])
  ],
  targets: [
    .target(name: "ImageAICore"),
    .executableTarget(
      name: "ImageAI",
      dependencies: ["ImageAICore"]
    ),
    .testTarget(
      name: "ImageAICoreTests",
      dependencies: ["ImageAICore"]
    ),
  ]
)
