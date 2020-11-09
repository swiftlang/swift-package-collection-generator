//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import PackageModel
import XCTest

@testable import PackageCollectionModel

class PackageCollectionModelTests: XCTestCase {
    func testCodable() throws {
        let packages = [
            PackageCollection.Package(
                url: URL(string: "https://package-collection-tests.com/repos/foobar.git")!,
                summary: "Package Foobar",
                versions: [
                    PackageCollection.Package.Version(
                        version: "1.3.2",
                        packageName: "Foobar",
                        targets: [.init(name: "Foo", moduleName: "Foo")],
                        products: [.init(name: "Bar", type: .library(.automatic), targets: ["Foo"])],
                        toolsVersion: "5.2",
                        verifiedPlatforms: [.init(name: "macOS")],
                        verifiedSwiftVersions: ["5.2"],
                        license: .init(name: "Apache-2.0", url: URL(string: "https://package-collection-tests.com/repos/foobar/LICENSE")!)
                    ),
                ],
                readmeURL: URL(string: "https://package-collection-tests.com/repos/foobar/README")!
            ),
        ]
        let packageCollection = PackageCollection(
            title: "Test Package Collection",
            overview: "A test package collection",
            keywords: ["swift packages"],
            packages: packages,
            formatVersion: .v1_0,
            generatedAt: Date()
        )

        let data = try JSONEncoder().encode(packageCollection)
        let decoded = try JSONDecoder().decode(PackageCollection.self, from: data)
        XCTAssertEqual(packageCollection, decoded)
    }
}
