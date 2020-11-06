// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-package-collection-generator",
    // Required for JSONEncoder/Decoder formatting and ISO-8601 support
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "PackageCollectionModel", targets: ["PackageCollectionModel"]),
        .library(name: "PackageCollectionGenerator", targets: ["PackageCollectionGenerator"]),
        .executable(name: "package-collection-generate", targets: ["PackageCollectionGeneratorExecutable"]),
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

        .target(name: "PackageCollectionModel", dependencies: [
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),
        .target(name: "PackageCollectionGenerator", dependencies: [
            "PackageCollectionModel",
            "Utilities",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackageCollectionGeneratorExecutable", dependencies: ["PackageCollectionGenerator"]),

        .target(name: "TestUtilities", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),

        .testTarget(name: "PackageCollectionModelTests", dependencies: ["PackageCollectionModel"]),
        .testTarget(name: "PackageCollectionGeneratorTests", dependencies: ["PackageCollectionGenerator"]),
        .testTarget(name: "PackageCollectionGeneratorExecutableTests", dependencies: [
            "PackageCollectionGeneratorExecutable",
            "TestUtilities",
        ]),
    ]
)
