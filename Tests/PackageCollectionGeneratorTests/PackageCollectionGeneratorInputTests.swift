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
import XCTest

@testable import PackageCollectionGenerator
import TSCBasic

class PackageCollectionGeneratorInputTests: XCTestCase {
    func testLoadFromFile() throws {
        let expectedInput = PackageCollectionGeneratorInput(
            name: "Test Package Collection",
            overview: "A test package collection",
            keywords: ["swift packages"],
            packages: [
                PackageCollectionGeneratorInput.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/foobar.git")!,
                    summary: "Package Foobar",
                    keywords: ["test package"],
                    versions: ["0.2.0", "0.1.0"],
                    excludedProducts: ["Foo"],
                    excludedTargets: ["Bar"],
                    readmeURL: URL(string: "https://package-collection-tests.com/repos/foobar/README")!
                ),
                PackageCollectionGeneratorInput.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/foobaz.git")!
                ),
            ],
            author: .init(name: "Jane Doe")
        )

        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test-input.json")
        let input = try JSONDecoder().decode(
            PackageCollectionGeneratorInput.self,
            from: Data(try localFileSystem.readFileContents(inputFilePath).contents)
        )

        XCTAssertEqual(expectedInput, input)
    }

    func testCodable() throws {
        let input = PackageCollectionGeneratorInput(
            name: "Test Package Collection",
            overview: "A test package collection",
            keywords: ["swift packages"],
            packages: [
                PackageCollectionGeneratorInput.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/foobar.git")!,
                    summary: "Package Foobar",
                    keywords: ["test package"],
                    versions: ["1.3.2"],
                    excludedProducts: ["Foo"],
                    excludedTargets: ["Bar"],
                    readmeURL: URL(string: "https://package-collection-tests.com/repos/foobar/README")!
                ),
            ],
            author: .init(name: "Jane Doe")
        )

        let data = try JSONEncoder().encode(input)
        let decoded = try JSONDecoder().decode(PackageCollectionGeneratorInput.self, from: data)
        XCTAssertEqual(input, decoded)
    }
}
