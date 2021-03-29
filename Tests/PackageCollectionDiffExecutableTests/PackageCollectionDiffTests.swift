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

import XCTest

@testable import PackageCollectionDiff
@testable import TestUtilities
import TSCBasic

final class PackageCollectionDiffTests: XCTestCase {
    func test_help() throws {
        XCTAssert(try executeCommand(command: "package-collection-diff --help")
            .stdout.contains("USAGE: package-collection-diff <collection-one-path> <collection-two-path> [--verbose]"))
    }

    func test_same() throws {
        let path = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test.json")

        XCTAssert(try executeCommand(command: "package-collection-diff \(path.pathString) \(path.pathString)")
            .stdout.contains("The package collections are the same."))
    }

    func test_differentGeneratedAt() throws {
        let pathOne = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test.json")
        let pathTwo = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test_diff_generated_at.json")

        // Two collections with only `generatedAt` being different are considered the same
        XCTAssert(try executeCommand(command: "package-collection-diff \(pathOne.pathString) \(pathTwo.pathString)")
            .stdout.contains("The package collections are the same."))
    }

    func test_differentPackages() throws {
        let pathOne = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test.json")
        let pathTwo = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test_diff_packages.json")

        XCTAssert(try executeCommand(command: "package-collection-diff \(pathOne.pathString) \(pathTwo.pathString)")
            .stdout.contains("The package collections are different."))
    }
}
