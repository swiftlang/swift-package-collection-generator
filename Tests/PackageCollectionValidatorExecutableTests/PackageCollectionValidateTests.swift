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

@testable import PackageCollectionValidator
@testable import TestUtilities
import TSCBasic

final class PackageCollectionValidateTests: XCTestCase {
    func test_help() throws {
        XCTAssert(try executeCommand(command: "package-collection-validate --help")
            .stdout.contains("USAGE: package-collection-validate <input-path> [--warnings-as-errors] [--verbose]"))
    }

    func test_good() throws {
        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "valid.json")

        XCTAssert(try executeCommand(command: "package-collection-validate --verbose \(inputFilePath.pathString)")
            .stdout.contains("The package collection is valid."))
    }

    func test_badJSON() throws {
        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "bad.json")

        XCTAssert(try executeCommand(command: "package-collection-validate --verbose \(inputFilePath.pathString)", exitCode: .failure)
            .stderr.contains("Failed to parse package collection"))
    }

    func test_collectionWithErrors() throws {
        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "error-no-packages.json")

        XCTAssert(try executeCommand(command: "package-collection-validate --verbose \(inputFilePath.pathString)", exitCode: .failure)
            .stdout.contains("must contain at least one package"))
    }

    func test_collectionWithWarnings() throws {
        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "warning-too-many-versions.json")

        XCTAssert(try executeCommand(command: "package-collection-validate --verbose \(inputFilePath.pathString)")
            .stdout.contains("includes too many major versions"))
    }

    func test_warningsAsErrors() throws {
        let inputFilePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "warning-too-many-versions.json")

        XCTAssert(try executeCommand(command: "package-collection-validate --warnings-as-errors --verbose \(inputFilePath.pathString)", exitCode: .failure)
            .stderr.contains("includes too many major versions"))
    }
}
