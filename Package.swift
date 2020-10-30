// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-packages-feed-generator",
    // Required for JSONEncoder/Decoder formatting and ISO-8601 support
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "PackageFeedModel", targets: ["PackageFeedModel"]),
    ],
    dependencies: [
        // FIXME: need semver
        .package(name: "SwiftPM", url: "https://github.com/apple/swift-package-manager.git", .branch("main")),
    ],
    targets: [
        .target(name: "PackageFeedModel", dependencies: [
            .product(name: "SwiftPMDataModel", package: "SwiftPM"),
        ]),

        .testTarget(name: "PackageFeedModelTests", dependencies: ["PackageFeedModel"]),
    ]
)
