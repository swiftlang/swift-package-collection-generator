//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Feed Generator open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Package Feed Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Feed Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import TSCBasic
import XCTest

@testable import PackageFeedGenerator

class PackageFeedGeneratorInputTests: XCTestCase {
    func testLoadFromFile() throws {
        let expectedInput = PackageFeedGeneratorInput(
            title: "Test Package Feed",
            overview: "A test package feed",
            keywords: ["swift packages"],
            packages: [
                PackageFeedGeneratorInput.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/foobar.git")!,
                    summary: "Package Foobar",
                    versions: ["0.2.0", "0.1.0"],
                    excludedProducts: ["Foo"],
                    excludedTargets: ["Bar"]
                ),
                PackageFeedGeneratorInput.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/foobaz.git")!,
                    summary: nil,
                    versions: nil,
                    excludedProducts: nil,
                    excludedTargets: nil
                ),
            ]
        )

        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test-input.json")
        let input = try JSONDecoder().decode(
            PackageFeedGeneratorInput.self,
            from: Data(try localFileSystem.readFileContents(inputFilePath).contents)
        )

        XCTAssertEqual(expectedInput, input)
    }

    func testCodable() throws {
        let input = PackageFeedGeneratorInput(
            title: "Test Package Feed",
            overview: "A test package feed",
            keywords: ["swift packages"],
            packages: [
                PackageFeedGeneratorInput.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/foobar.git")!,
                    summary: "Package Foobar",
                    versions: ["1.3.2"],
                    excludedProducts: ["Foo"],
                    excludedTargets: ["Bar"]
                ),
            ]
        )

        let data = try JSONEncoder().encode(input)
        let decoded = try JSONDecoder().decode(PackageFeedGeneratorInput.self, from: data)
        XCTAssertEqual(input, decoded)
    }
}
