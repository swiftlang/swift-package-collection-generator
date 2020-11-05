// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-packages-feed-generator",
    // Required for JSONEncoder/Decoder formatting and ISO-8601 support
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "PackageFeedModel", targets: ["PackageFeedModel"]),
        .library(name: "PackagesFeedGenerator", targets: ["PackagesFeedGenerator"]),
        .executable(name: "packages-feed-generate", targets: ["PackagesFeedGeneratorExecutable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.3.0")),
        // FIXME: need semver
        .package(name: "SwiftPM", url: "https://github.com/apple/swift-package-manager.git", .branch("main")),
    ],
    targets: [
        .target(name: "Utilities", dependencies: [
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),

        .target(name: "PackageFeedModel", dependencies: [
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),
        .target(name: "PackagesFeedGenerator", dependencies: [
            "PackageFeedModel",
            "Utilities",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackagesFeedGeneratorExecutable", dependencies: ["PackagesFeedGenerator"]),

        .target(name: "TestUtilities", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),

        .testTarget(name: "PackageFeedModelTests", dependencies: ["PackageFeedModel"]),
        .testTarget(name: "PackagesFeedGeneratorTests", dependencies: ["PackagesFeedGenerator"]),
        .testTarget(name: "PackagesFeedGeneratorExecutableTests", dependencies: [
            "PackagesFeedGeneratorExecutable",
            "TestUtilities",
        ]),
    ]
)
