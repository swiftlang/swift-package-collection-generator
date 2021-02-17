// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-package-collection-generator",
    // Required for JSONEncoder/Decoder formatting and ISO-8601 support
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "PackageCollectionGenerator", targets: ["PackageCollectionGenerator"]),
        .executable(name: "package-collection-generate", targets: ["PackageCollectionGeneratorExecutable"]),
        .library(name: "PackageCollectionSigner", targets: ["PackageCollectionSigner"]),
        .executable(name: "package-collection-sign", targets: ["PackageCollectionSignerExecutable"]),
        .library(name: "PackageCollectionValidator", targets: ["PackageCollectionValidator"]),
        .executable(name: "package-collection-validate", targets: ["PackageCollectionValidatorExecutable"]),
        .library(name: "PackageCollectionDiff", targets: ["PackageCollectionDiff"]),
        .executable(name: "package-collection-diff", targets: ["PackageCollectionDiffExecutable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.3.0")),
        // FIXME: need semver
        .package(name: "SwiftPM", url: "https://github.com/yim-lee/swift-package-manager.git", .branch("wire-signing-all")),
    ],
    targets: [
        .target(name: "Utilities", dependencies: [
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
        ]),

        .target(name: "PackageCollectionGenerator", dependencies: [
            "Utilities",
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackageCollectionGeneratorExecutable", dependencies: ["PackageCollectionGenerator"]),

        .target(name: "PackageCollectionSigner", dependencies: [
            "Utilities",
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackageCollectionSignerExecutable", dependencies: ["PackageCollectionSigner"]),

        .target(name: "PackageCollectionValidator", dependencies: [
            "Utilities",
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackageCollectionValidatorExecutable", dependencies: ["PackageCollectionValidator"]),

        .target(name: "PackageCollectionDiff", dependencies: [
            "Utilities",
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "PackageCollectionDiffExecutable", dependencies: ["PackageCollectionDiff"]),

        .target(name: "TestUtilities", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftPMPackageCollections", package: "SwiftPM"),
        ]),

        .testTarget(name: "PackageCollectionGeneratorTests", dependencies: ["PackageCollectionGenerator"]),
        .testTarget(name: "PackageCollectionGeneratorExecutableTests", dependencies: [
            "PackageCollectionGeneratorExecutable",
            "TestUtilities",
        ]),

        .testTarget(name: "PackageCollectionSignerExecutableTests", dependencies: [
            "PackageCollectionSignerExecutable",
            "TestUtilities",
        ]),

        .testTarget(name: "PackageCollectionValidatorExecutableTests", dependencies: [
            "PackageCollectionValidatorExecutable",
            "TestUtilities",
        ]),

        .testTarget(name: "PackageCollectionDiffExecutableTests", dependencies: [
            "PackageCollectionDiffExecutable",
            "TestUtilities",
        ]),
    ]
)
