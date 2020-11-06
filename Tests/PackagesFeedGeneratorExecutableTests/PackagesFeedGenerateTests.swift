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
import PackageFeedModel
@testable import PackagesFeedGenerator
@testable import TestUtilities
import TSCBasic
import TSCUtility
import XCTest

final class PackagesFeedGenerateTests: XCTestCase {
    func test_help() throws {
        XCTAssert(try executeCommand(command: "packages-feed-generate --help")
            .stdout.contains("USAGE: packages-feed-generate <input-path> <output-path> [--working-directory-path <working-directory-path>] [--revision <revision>] [--verbose]"))
    }

    func test_endToEnd() throws {
        try withTemporaryDirectory(prefix: "PackageFeedToolTests", removeTreeOnDeinit: true) { tmpDir in
            // TestRepoOne has tags [0.1.0]
            let repoOneArchivePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "TestRepoOne.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoOneArchivePath.pathString])

            // TestRepoTwo has tags [0.1.0, 0.2.0]
            let repoTwoArchivePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "TestRepoTwo.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoTwoArchivePath.pathString])

            // TestRepoThree has tags [1.0.0]
            let repoThreeArchivePath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "TestRepoThree.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoThreeArchivePath.pathString])

            let jsonEncoder = JSONEncoder()
            if #available(macOS 10.15, *) {
                #if os(macOS)
                jsonEncoder.outputFormatting = [.withoutEscapingSlashes]
                #else
                jsonEncoder.outputFormatting = [.sortedKeys]
                #endif
            }

            // Prepare input.json
            let input = PackagesFeedGeneratorInput(
                title: "Test Package Feed",
                overview: "A few test packages",
                keywords: ["swift packages"],
                packages: [
                    PackagesFeedGeneratorInput.Package(
                        url: URL(string: "https://package-feed-tests.com/repos/TestRepoOne.git")!,
                        summary: "Package Foo",
                        versions: nil,
                        excludedProducts: nil,
                        excludedTargets: nil
                    ),
                    PackagesFeedGeneratorInput.Package(
                        url: URL(string: "https://package-feed-tests.com/repos/TestRepoTwo.git")!,
                        summary: "Package Foo & Bar",
                        versions: nil,
                        excludedProducts: nil,
                        excludedTargets: nil
                    ),
                    PackagesFeedGeneratorInput.Package(
                        url: URL(string: "https://package-feed-tests.com/repos/TestRepoThree.git")!,
                        summary: "Package Baz",
                        versions: ["1.0.0"],
                        excludedProducts: nil,
                        excludedTargets: nil
                    ),
                ]
            )
            let inputData = try jsonEncoder.encode(input)
            let inputFilePath = tmpDir.appending(component: "input.json")
            try localFileSystem.writeFileContents(inputFilePath, bytes: ByteString(inputData))

            // Where to write the generated feed
            let outputFilePath = tmpDir.appending(component: "package-feed.json")
            // `tmpDir` is where we extract the repos so use it as the working directory so we won't actually doing any cloning
            let workingDirectoryPath = tmpDir

            XCTAssert(try executeCommand(command: "packages-feed-generate --verbose \(inputFilePath.pathString) \(outputFilePath.pathString) --working-directory-path \(workingDirectoryPath.pathString)")
                .stdout.contains("Package feed saved to \(outputFilePath.pathString)"))

            let expectedPackages = [
                PackageFeed.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/TestRepoOne.git")!,
                    summary: "Package Foo",
                    versions: [
                        PackageFeed.Package.Version(
                            version: "0.1.0",
                            packageName: "TestPackageOne",
                            targets: [.init(name: "Foo", moduleName: "Foo")],
                            products: [.init(name: "Foo", type: .library(.automatic), targets: ["Foo"])],
                            toolsVersion: "5.2.0",
                            verifiedPlatforms: nil,
                            verifiedSwiftVersions: nil,
                            license: nil
                        ),
                    ],
                    readmeURL: nil
                ),
                PackageFeed.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/TestRepoTwo.git")!,
                    summary: "Package Foo & Bar",
                    versions: [
                        PackageFeed.Package.Version(
                            version: "0.2.0",
                            packageName: "TestPackageTwo",
                            targets: [
                                .init(name: "Bar", moduleName: "Bar"),
                                .init(name: "Foo", moduleName: "Foo"),
                            ],
                            products: [
                                .init(name: "Bar", type: .library(.automatic), targets: ["Bar"]),
                                .init(name: "Foo", type: .library(.automatic), targets: ["Foo"]),
                            ],
                            toolsVersion: "5.2.0",
                            verifiedPlatforms: nil,
                            verifiedSwiftVersions: nil,
                            license: nil
                        ),
                        PackageFeed.Package.Version(
                            version: "0.1.0",
                            packageName: "TestPackageTwo",
                            targets: [.init(name: "Bar", moduleName: "Bar")],
                            products: [.init(name: "Bar", type: .library(.automatic), targets: ["Bar"])],
                            toolsVersion: "5.2.0",
                            verifiedPlatforms: nil,
                            verifiedSwiftVersions: nil,
                            license: nil
                        ),
                    ],
                    readmeURL: nil
                ),
                PackageFeed.Package(
                    url: URL(string: "https://package-feed-tests.com/repos/TestRepoThree.git")!,
                    summary: "Package Baz",
                    versions: [
                        PackageFeed.Package.Version(
                            version: "1.0.0",
                            packageName: "TestPackageThree",
                            targets: [.init(name: "Baz", moduleName: "Baz")],
                            products: [.init(name: "Baz", type: .library(.automatic), targets: ["Baz"])],
                            toolsVersion: "5.2.0",
                            verifiedPlatforms: nil,
                            verifiedSwiftVersions: nil,
                            license: nil
                        ),
                    ],
                    readmeURL: nil
                ),
            ]

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601

            // Assert the generated package feed
            let feedData = try localFileSystem.readFileContents(outputFilePath).contents
            let packageFeed = try jsonDecoder.decode(PackageFeed.self, from: Data(feedData))
            XCTAssertEqual(input.title, packageFeed.title)
            XCTAssertEqual(input.overview, packageFeed.overview)
            XCTAssertEqual(input.keywords, packageFeed.keywords)
            XCTAssertEqual(expectedPackages, packageFeed.packages)
        }
    }
}
