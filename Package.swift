// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "applenotary",
    dependencies: [
        .package(url: "https://github.com/objecthub/swift-commandlinekit", from: "0.2.4"),
    ],
    targets: [
        .target(
            name: "applenotary",
            dependencies: ["CommandLineKit"]),
        .testTarget(
            name: "applenotaryTests",
            dependencies: ["applenotary"]),
    ]
)
