// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "applenotary",
    platforms: [
        .macOS(.v10_12)
    ],
    dependencies: [
        .package(url: "https://github.com/objecthub/swift-commandlinekit", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "applenotary",
            dependencies: ["CommandLineKit"]),
        .testTarget(
            name: "applenotaryTests",
            dependencies: ["applenotary"]),
    ],
    swiftLanguageVersions: [.v5]
)
