//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020-2023 Apple Inc. and the Swift Package Collection Generator project authors
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

import Basics
@testable import PackageCollectionGenerator
import PackageCollectionsModel
@testable import TestUtilities
import struct TSCBasic.ByteString
import TSCUtility

final class PackageCollectionGenerateTests: XCTestCase {
    typealias Model = PackageCollectionModel.V1

    func test_help() throws {
        let help = try executeCommand(command: "package-collection-generate --help").stdout
        let expectedUsageDescription = "USAGE: package-collection-generate <input-path> <output-path> [--working-directory-path <working-directory-path>] [--revision <revision>] [--auth-token <auth-token> ...] [--pretty-printed] [--verbose]"
        XCTAssert(help.contains(expectedUsageDescription), "Help did not contain expected usage description, instead it had:\n\(help)")
    }

    func test_endToEnd() async throws {
        try await withTemporaryDirectory(prefix: "PackageCollectionToolTests", removeTreeOnDeinit: true) { tmpDir in
            // TestRepoOne has tags [0.1.0]
            let repoOneArchivePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "TestRepoOne.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoOneArchivePath.pathString])

            // TestRepoTwo has tags [0.1.0, 0.2.0]
            let repoTwoArchivePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "TestRepoTwo.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoTwoArchivePath.pathString])

            // TestRepoThree has tags [1.0.0]
            let repoThreeArchivePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "TestRepoThree.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoThreeArchivePath.pathString])

            let signer = PackageCollectionModel.V1.Signer(
                type: "ADP",
                commonName: "J. Appleseed",
                organizationalUnitName: "A1",
                organizationName: "Appleseed Inc."
            )

            // Prepare input.json
            let input = PackageCollectionGeneratorInput(
                name: "Test Package Collection",
                overview: "A few test packages",
                keywords: ["swift packages"],
                packages: [
                    PackageCollectionGeneratorInput.Package(
                        url: URL(string: "https://package-collection-tests.com/repos/TestRepoOne.git")!,
                        summary: "Package Foo"
                    ),
                    PackageCollectionGeneratorInput.Package(
                        url: URL(string: "https://package-collection-tests.com/repos/TestRepoTwo.git")!,
                        identity: "repos.two",
                        summary: "Package Foo & Bar",
                        signer: signer
                    ),
                    PackageCollectionGeneratorInput.Package(
                        url: URL(string: "https://package-collection-tests.com/repos/TestRepoThree.git")!,
                        summary: "Package Baz",
                        versions: ["1.0.0"]
                    ),
                ]
            )
            let jsonEncoder = JSONEncoder.makeWithDefaults()
            let inputData = try jsonEncoder.encode(input)
            let inputFilePath = tmpDir.appending(component: "input.json")
            try localFileSystem.writeFileContents(inputFilePath, bytes: ByteString(inputData))

            let expectedPackages = [
                Model.Collection.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/TestRepoOne.git")!,
                    summary: "Package Foo",
                    keywords: nil,
                    versions: [
                        Model.Collection.Package.Version(
                            version: "0.1.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageOne",
                                    targets: [.init(name: "Foo", moduleName: "Foo")],
                                    products: [.init(name: "Foo", type: .library(.automatic), targets: ["Foo"])],
                                    minimumPlatformVersions: [.init(name: "macos", version: "10.15")]
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: nil,
                            createdAt: nil
                        ),
                    ],
                    readmeURL: nil,
                    license: nil
                ),
                Model.Collection.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/TestRepoTwo.git")!,
                    identity: "repos.two",
                    summary: "Package Foo & Bar",
                    keywords: nil,
                    versions: [
                        Model.Collection.Package.Version(
                            version: "0.2.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageTwo",
                                    targets: [
                                        .init(name: "Bar", moduleName: "Bar"),
                                        .init(name: "Foo", moduleName: "Foo"),
                                    ],
                                    products: [
                                        .init(name: "Bar", type: .library(.automatic), targets: ["Bar"]),
                                        .init(name: "Foo", type: .library(.automatic), targets: ["Foo"]),
                                    ],
                                    minimumPlatformVersions: nil
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: signer,
                            createdAt: nil
                        ),
                        Model.Collection.Package.Version(
                            version: "0.1.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageTwo",
                                    targets: [.init(name: "Bar", moduleName: "Bar")],
                                    products: [.init(name: "Bar", type: .library(.automatic), targets: ["Bar"])],
                                    minimumPlatformVersions: nil
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: signer,
                            createdAt: nil
                        ),
                    ],
                    readmeURL: nil,
                    license: nil
                ),
                Model.Collection.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/TestRepoThree.git")!,
                    summary: "Package Baz",
                    keywords: nil,
                    versions: [
                        Model.Collection.Package.Version(
                            version: "1.0.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageThree",
                                    targets: [.init(name: "Baz", moduleName: "Baz")],
                                    products: [.init(name: "Baz", type: .library(.automatic), targets: ["Baz"])],
                                    minimumPlatformVersions: nil
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: nil,
                            createdAt: nil
                        ),
                    ],
                    readmeURL: nil,
                    license: nil
                ),
            ]

            #if os(macOS) // XCTAttachment is available in Xcode only
            // Run command with both pretty-printed enabled and disabled (which is the default, with no flag).
            for prettyFlag in ["--pretty-printed", nil] {
                // Where to write the generated collection
                let outputFilePath = tmpDir.appending(component: "package-collection\(prettyFlag ?? "").json")
                // `tmpDir` is where we extract the repos so use it as the working directory so we won't actually doing any cloning
                let workingDirectoryPath = tmpDir

                let flags = [
                    "--verbose",
                    prettyFlag,
                    inputFilePath.pathString,
                    outputFilePath.pathString,
                    "--working-directory-path",
                    workingDirectoryPath.pathString,
                ].compactMap { $0 }
                let cmd = try PackageCollectionGenerate.parse(flags)
                try await cmd.run()

                let jsonDecoder = JSONDecoder.makeWithDefaults()

                // Assert the generated package collection
                let collectionData = try localFileSystem.readFileContents(outputFilePath).contents
                let packageCollection = try jsonDecoder.decode(Model.Collection.self, from: Data(collectionData))
                XCTAssertEqual(input.name, packageCollection.name)
                XCTAssertEqual(input.overview, packageCollection.overview)
                XCTAssertEqual(input.keywords, packageCollection.keywords)
                XCTAssertEqual(expectedPackages, packageCollection.packages)

                add(XCTAttachment(contentsOfFile: outputFilePath.asURL))
            }
            #endif
        }
    }

    func test_excludedVersions() async throws {
        try await withTemporaryDirectory(prefix: "PackageCollectionToolTests", removeTreeOnDeinit: true) { tmpDir in
            // TestRepoOne has tags [0.1.0]
            let repoOneArchivePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "TestRepoOne.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoOneArchivePath.pathString])

            // TestRepoTwo has tags [0.1.0, 0.2.0]
            let repoTwoArchivePath = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "TestRepoTwo.tgz")
            try systemQuietly(["tar", "-x", "-v", "-C", tmpDir.pathString, "-f", repoTwoArchivePath.pathString])

            // Prepare input.json
            let input = PackageCollectionGeneratorInput(
                name: "Test Package Collection",
                overview: "A few test packages",
                keywords: ["swift packages"],
                packages: [
                    PackageCollectionGeneratorInput.Package(
                        url: URL(string: "https://package-collection-tests.com/repos/TestRepoOne.git")!,
                        summary: "Package Foo"
                    ),
                    PackageCollectionGeneratorInput.Package(
                        url: URL(string: "https://package-collection-tests.com/repos/TestRepoTwo.git")!,
                        identity: "repos.two",
                        summary: "Package Foo & Bar",
                        excludedVersions: ["0.1.0"]
                    ),
                ]
            )
            let jsonEncoder = JSONEncoder.makeWithDefaults()
            let inputData = try jsonEncoder.encode(input)
            let inputFilePath = tmpDir.appending(component: "input.json")
            try localFileSystem.writeFileContents(inputFilePath, bytes: ByteString(inputData))

            // Where to write the generated collection
            let outputFilePath = tmpDir.appending(component: "package-collection.json")
            // `tmpDir` is where we extract the repos so use it as the working directory so we won't actually doing any cloning
            let workingDirectoryPath = tmpDir

            let cmd = try PackageCollectionGenerate.parse([
                "--verbose",
                inputFilePath.pathString,
                outputFilePath.pathString,
                "--working-directory-path",
                workingDirectoryPath.pathString,
            ])
            try await cmd.run()

            let expectedPackages = [
                Model.Collection.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/TestRepoOne.git")!,
                    summary: "Package Foo",
                    keywords: nil,
                    versions: [
                        Model.Collection.Package.Version(
                            version: "0.1.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageOne",
                                    targets: [.init(name: "Foo", moduleName: "Foo")],
                                    products: [.init(name: "Foo", type: .library(.automatic), targets: ["Foo"])],
                                    minimumPlatformVersions: [.init(name: "macos", version: "10.15")]
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: nil,
                            createdAt: nil
                        ),
                    ],
                    readmeURL: nil,
                    license: nil
                ),
                Model.Collection.Package(
                    url: URL(string: "https://package-collection-tests.com/repos/TestRepoTwo.git")!,
                    identity: "repos.two",
                    summary: "Package Foo & Bar",
                    keywords: nil,
                    versions: [
                        Model.Collection.Package.Version(
                            version: "0.2.0",
                            summary: nil,
                            manifests: [
                                "5.2": Model.Collection.Package.Version.Manifest(
                                    toolsVersion: "5.2",
                                    packageName: "TestPackageTwo",
                                    targets: [
                                        .init(name: "Bar", moduleName: "Bar"),
                                        .init(name: "Foo", moduleName: "Foo"),
                                    ],
                                    products: [
                                        .init(name: "Bar", type: .library(.automatic), targets: ["Bar"]),
                                        .init(name: "Foo", type: .library(.automatic), targets: ["Foo"]),
                                    ],
                                    minimumPlatformVersions: nil
                                ),
                            ],
                            defaultToolsVersion: "5.2",
                            verifiedCompatibility: nil,
                            license: nil,
                            author: nil,
                            signer: nil,
                            createdAt: nil
                        ),
                    ],
                    readmeURL: nil,
                    license: nil
                ),
            ]

            let jsonDecoder = JSONDecoder.makeWithDefaults()

            // Assert the generated package collection
            let collectionData = try localFileSystem.readFileContents(outputFilePath).contents
            let packageCollection = try jsonDecoder.decode(Model.Collection.self, from: Data(collectionData))
            XCTAssertEqual(input.name, packageCollection.name)
            XCTAssertEqual(input.overview, packageCollection.overview)
            XCTAssertEqual(input.keywords, packageCollection.keywords)
            XCTAssertEqual(expectedPackages, packageCollection.packages)
        }
    }
}
