//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Packages Feed Generator open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Packages Feed Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Packages Feed Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import PackageModel
import XCTest

@testable import PackageFeedModel

class PackageFeedModelTests: XCTestCase {
    func test_PackageFeed_Codable() throws {
        let packages = [
            PackageFeed.Package(
                url: URL(string: "https://package-feed-tests.com/repos/foobar")!,
                summary: "Package Foobar",
                versions: [
                    PackageFeed.Package.Version(
                        version: "1.3.2",
                        packageName: "Foobar",
                        targets: [.init(name: "Foo")],
                        products: [.init(name: "Bar", type: .library(.automatic), targets: ["Foo"])],
                        supportedPlatforms: [.init(name: "macOS")],
                        supportedSwiftVersions: ["5.2"],
                        license: .init(name: "Apache-2.0", url: URL(string: "https://package-feed-tests.com/repos/foobar/LICENSE")!)
                    ),
                ],
                readmeURL: URL(string: "https://package-feed-tests.com/repos/foobar/README")!
            ),
        ]
        let packageFeed = PackageFeed(
            title: "Test Package Feed",
            overview: "A test package feed",
            keywords: ["swift packages"],
            packages: packages,
            formatVersion: .v1_0,
            generatedAt: Date()
        )

        let data = try JSONEncoder().encode(packageFeed)
        let decoded = try JSONDecoder().decode(PackageFeed.self, from: data)
        XCTAssertEqual(packageFeed, decoded)
    }
}
