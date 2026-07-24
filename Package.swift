// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AwakeTime",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "AwakeTimeKit", targets: ["AwakeTimeKit"]),
    .executable(name: "AwakeTime", targets: ["AwakeTimeApp"]),
  ],
  targets: [
    .target(
      name: "AwakeTimeKit"
    ),
    .executableTarget(
      name: "AwakeTimeApp",
      dependencies: ["AwakeTimeKit"]
    ),
    .testTarget(
      name: "AwakeTimeKitTests",
      dependencies: ["AwakeTimeKit"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
