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

import ArgumentParser
import Foundation

import Backtrace
import Basics
import PackageCollectionsModel
import PackageModel
import TSCBasic
import TSCUtility
import Utilities

@main
public struct PackageCollectionGenerate: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Generate a package collection from the given list of packages."
    )

    @Argument(help: "The path to the JSON document containing the list of packages to be processed")
    private var inputPath: String

    @Argument(help: "The path to write the generated package collection to")
    private var outputPath: String

    @Option(help:
        """
        The path to the working directory where package repositories may have been cloned previously. \
        A package repository that already exists in the directory will be updated rather than cloned again.\n\n\
        Be warned that the tool does not distinguish these directories by their corresponding git repository URL--\
        different repositories with the same name will end up in the same directory.\n\n\
        Temporary directories will be used instead if this argument is not specified.
        """
    )
    private var workingDirectoryPath: String?

    @Option(help: "The revision number of the generated package collection")
    private var revision: Int?

    @Option(parsing: .upToNextOption, help:
        """
        Auth tokens each in the format of type:host:token for retrieving additional package metadata via source
        hosting platform APIs. Currently only GitHub APIs are supported. An example token would be github:github.com:<TOKEN>.
        """)
    private var authToken: [String] = []

    @Flag(name: .long, help: "Format output using friendly indentation and line-breaks.")
    private var prettyPrinted: Bool = false

    @Flag(name: .shortAndLong, help: "Show extra logging for debugging purposes.")
    private var verbose: Bool = false

    typealias Model = PackageCollectionModel.V1

    public init() {}

    public func run() throws {
        Backtrace.install()

        // Parse auth tokens
        let authTokens = self.authToken.reduce(into: [AuthTokenType: String]()) { authTokens, authToken in
            let parts = authToken.components(separatedBy: ":")
            guard parts.count == 3, let type = AuthTokenType.from(type: parts[0], host: parts[1]) else {
                print("Ignoring invalid auth token '\(authToken)'", inColor: .yellow, verbose: self.verbose)
                return
            }
            authTokens[type] = parts[2]
        }
        if !self.authToken.isEmpty {
            print("Using auth tokens: \(authTokens.keys)", inColor: .cyan, verbose: self.verbose)
        }

        print("Using input file located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        // Get the list of packages to process
        let jsonDecoder = JSONDecoder.makeWithDefaults()
        let input = try jsonDecoder.decode(PackageCollectionGeneratorInput.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))
        print("\(input)", verbose: self.verbose)

        let githubPackageMetadataProvider = GitHubPackageMetadataProvider(authTokens: authTokens)

        // Generate metadata for each package
        let packages: [Model.Collection.Package] = input.packages.compactMap { package in
            do {
                let packageMetadata = try self.generateMetadata(for: package, metadataProvider: githubPackageMetadataProvider, jsonDecoder: jsonDecoder)
                print("\(packageMetadata)", verbose: self.verbose)

                guard !packageMetadata.versions.isEmpty else {
                    printError("Skipping package \(package.url) because it does not have any valid versions.")
                    return nil
                }

                return packageMetadata
            } catch {
                printError("Failed to generate metadata for package \(package.url): \(error)")
                return nil
            }
        }

        guard !packages.isEmpty else {
            printError("Failed to create package collection because it does not have any valid packages.")
            return
        }

        // Construct the package collection
        let packageCollection = Model.Collection(
            name: input.name,
            overview: input.overview,
            keywords: input.keywords,
            packages: packages,
            formatVersion: .v1_0,
            revision: self.revision,
            generatedAt: Date(),
            generatedBy: input.author
        )

        // Make sure the output directory exists
        let outputAbsolutePath: AbsolutePath
        do {
            outputAbsolutePath = try AbsolutePath(validating: self.outputPath)
        } catch {
            outputAbsolutePath = try AbsolutePath(
                validating: self.outputPath,
                relativeTo: try AbsolutePath(validating: FileManager.default.currentDirectoryPath)
            )
        }
        let outputDirectory = outputAbsolutePath.parentDirectory
        try localFileSystem.createDirectory(outputDirectory, recursive: true)

        // Write the package collection
        let jsonEncoder = JSONEncoder.makeWithDefaults(sortKeys: true, prettyPrint: self.prettyPrinted, escapeSlashes: false)
        let jsonData = try jsonEncoder.encode(packageCollection)
        try jsonData.write(to: URL(fileURLWithPath: outputAbsolutePath.pathString))
        print("Package collection saved to \(outputAbsolutePath)", inColor: .cyan, verbose: self.verbose)
    }

    private func generateMetadata(for package: PackageCollectionGeneratorInput.Package,
                                  metadataProvider: PackageMetadataProvider,
                                  jsonDecoder: JSONDecoder) throws -> Model.Collection.Package {
        print("Processing Package(\(package.url))", inColor: .cyan, verbose: self.verbose)

        // Try to locate the directory where the repository might have been cloned to previously
        if let workingDirectoryPath = self.workingDirectoryPath {
            let workingDirectoryAbsolutePath: AbsolutePath
            do {
                workingDirectoryAbsolutePath = try AbsolutePath(validating: workingDirectoryPath)
            } catch {
                workingDirectoryAbsolutePath = try AbsolutePath(
                    validating: workingDirectoryPath,
                    relativeTo: try AbsolutePath(validating: FileManager.default.currentDirectoryPath)
                )
            }

            // Extract directory name from repository URL
            let repositoryURL = package.url.absoluteString
            if let repositoryName = GitURL.from(repositoryURL)?.repository {
                print("Extracted repository name from URL: \(repositoryName)", inColor: .green, verbose: self.verbose)

                let gitDirectoryPath = workingDirectoryAbsolutePath.appending(component: repositoryName)
                if localFileSystem.exists(gitDirectoryPath) {
                    // If directory exists, assume it has been cloned previously
                    print("\(gitDirectoryPath) exists", inColor: .yellow, verbose: self.verbose)
                    try GitUtilities.fetch(repositoryURL, at: gitDirectoryPath)
                } else {
                    // Else clone it
                    print("\(gitDirectoryPath) does not exist", inColor: .yellow, verbose: self.verbose)
                    try GitUtilities.clone(repositoryURL, to: gitDirectoryPath)
                }

                return try self.generateMetadata(
                    for: package,
                    gitDirectoryPath: gitDirectoryPath,
                    metadataProvider: metadataProvider,
                    jsonDecoder: jsonDecoder
                )
            }
        }

        // Fallback to tmp directory if we cannot use the working directory for some reason or it's unspecified
        return try withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // Clone the package repository
            try GitUtilities.clone(package.url.absoluteString, to: tmpDir)

            return try self.generateMetadata(
                for: package,
                gitDirectoryPath: tmpDir,
                metadataProvider: metadataProvider,
                jsonDecoder: jsonDecoder
            )
        }
    }

    private func generateMetadata(for package: PackageCollectionGeneratorInput.Package,
                                  gitDirectoryPath: AbsolutePath,
                                  metadataProvider: PackageMetadataProvider,
                                  jsonDecoder: JSONDecoder) throws -> Model.Collection.Package {
        var additionalMetadata: PackageBasicMetadata?
        do {
            additionalMetadata = try tsc_await { callback in metadataProvider.get(package.url, callback: callback) }
        } catch {
            printError("Failed to fetch additional metadata: \(error)")
        }
        if let additionalMetadata = additionalMetadata {
            print("Retrieved additional metadata: \(additionalMetadata)", verbose: self.verbose)
        }

        // Select versions if none specified
        var versions = try package.versions ?? self.defaultVersions(for: gitDirectoryPath)

        // Remove excluded versions
        if let excludedVersions = package.excludedVersions {
            print("Excluding: \(excludedVersions)", inColor: .yellow, verbose: self.verbose)
            let excludedVersionsSet = Set(excludedVersions)
            versions = versions.filter { !excludedVersionsSet.contains($0) }
        }

        // Load the manifest for each version and extract metadata
        let packageVersions: [Model.Collection.Package.Version] = versions.compactMap { version in
            do {
                let metadata = try self.generateMetadata(
                    for: version,
                    excludedProducts: package.excludedProducts.map { Set($0) } ?? [],
                    excludedTargets: package.excludedTargets.map { Set($0) } ?? [],
                    gitDirectoryPath: gitDirectoryPath,
                    jsonDecoder: jsonDecoder
                )

                guard metadata.manifests.values.first(where: { !$0.products.isEmpty }) != nil else {
                    printError("Skipping version \(version) because it does not have any products.")
                    return nil
                }
                guard metadata.manifests.values.first(where: { !$0.targets.isEmpty }) != nil else {
                    printError("Skipping version \(version) because it does not have any targets.")
                    return nil
                }

                return metadata
            } catch {
                printError("Failed to load package manifest for \(package.url) version \(version): \(error)")
                return nil
            }
        }
        return Model.Collection.Package(
            url: package.url,
            identity: package.identity,
            summary: package.summary ?? additionalMetadata?.summary,
            keywords: package.keywords ?? additionalMetadata?.keywords,
            versions: packageVersions,
            readmeURL: package.readmeURL ?? additionalMetadata?.readmeURL,
            license: additionalMetadata?.license
        )
    }

    private func generateMetadata(for version: String,
                                  excludedProducts: Set<String>,
                                  excludedTargets: Set<String>,
                                  gitDirectoryPath: AbsolutePath,
                                  jsonDecoder: JSONDecoder) throws -> Model.Collection.Package.Version
    {
        // Check out the git tag
        print("Checking out version \(version)", inColor: .yellow, verbose: self.verbose)
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "checkout", version)

        let gitTagInfo = try GitUtilities.tagInfo(version, for: gitDirectoryPath)

        let defaultManifest = try self.defaultManifest(
            excludedProducts: excludedProducts,
            excludedTargets: excludedTargets,
            gitDirectoryPath: gitDirectoryPath,
            jsonDecoder: jsonDecoder
        )
        // TODO: Use `describe` to obtain all manifest-related data, including version-specific manifests
        let manifests = [defaultManifest.toolsVersion: defaultManifest]

        return Model.Collection.Package.Version(
            version: version,
            summary: gitTagInfo?.message,
            manifests: manifests,
            defaultToolsVersion: defaultManifest.toolsVersion,
            verifiedCompatibility: nil,
            license: nil,
            createdAt: gitTagInfo?.createdAt
        )
    }

    private func defaultManifest(excludedProducts: Set<String>,
                                 excludedTargets: Set<String>,
                                 gitDirectoryPath: AbsolutePath,
                                 jsonDecoder: JSONDecoder) throws -> Model.Collection.Package.Version.Manifest
    {
        // Run `swift package describe --type json` to generate JSON package description
        let packageDescriptionJSON = try ShellUtilities.run(ShellUtilities.shell, "-c", "cd \(gitDirectoryPath) && swift package describe --type json")
        let packageDescription = try jsonDecoder.decode(PackageDescription.self, from: packageDescriptionJSON.data(using: .utf8) ?? Data())

        let products: [Model.Product] = packageDescription.products
            .filter { !excludedProducts.contains($0.name) }
            .map { product in
                Model.Product(
                    name: product.name,
                    type: Model.ProductType(from: product.type),
                    targets: product.targets
                )
            }
            .sorted { $0.name < $1.name }

        // Include only targets that are in at least one product.
        // Another approach is to use `target.product_memberships` but the way it is implemented produces a more concise list.
        let publicTargets = Set(products.map(\.targets).reduce(into: []) { result, targets in
            result.append(contentsOf: targets.filter { !excludedTargets.contains($0) })
        })

        let targets: [Model.Target] = packageDescription.targets
            .filter { publicTargets.contains($0.name) }
            .map { target in
                Model.Target(
                    name: target.name,
                    moduleName: target.c99name
                )
            }
            .sorted { $0.name < $1.name }

        var minimumPlatformVersions: [Model.PlatformVersion]?
        if let platforms = packageDescription.platforms, !platforms.isEmpty {
            minimumPlatformVersions = platforms.map { Model.PlatformVersion(name: $0.name, version: $0.version) }
        }

        return Model.Collection.Package.Version.Manifest(
            toolsVersion: packageDescription.tools_version,
            packageName: packageDescription.name,
            targets: targets,
            products: products,
            minimumPlatformVersions: minimumPlatformVersions
        )
    }

    private func defaultVersions(for gitDirectoryPath: AbsolutePath) throws -> [String] {
        // List all the tags
        let tags = try GitUtilities.listTags(for: gitDirectoryPath)
        print("Tags: \(tags)", inColor: .yellow, verbose: self.verbose)

        // Sort tags in descending order (non-semver tags are excluded)
        // By default, we want:
        //  - At most 3 minor versions per major version
        //  - Maximum of 2 majors
        //  - Maximum of 6 versions total
        var allVersions: [(tag: String, version: Version)] = tags.compactMap { tag in
            // Remove common "v" prefix which is supported by SwiftPM
            Version(tag.hasPrefix("v") ? String(tag.dropFirst(1)) : tag).map { (tag: tag, version: $0) }
        }
        allVersions.sort { $0.version > $1.version }

        var versions = [String]()
        var currentMajor: Int?
        var majorCount = 0
        var minorCount = 0
        for tagVersion in allVersions {
            if tagVersion.version.major != currentMajor {
                currentMajor = tagVersion.version.major
                majorCount += 1
                minorCount = 0
            }

            guard majorCount <= 2 else { break }
            guard minorCount < 3 else { continue }

            versions.append(tagVersion.tag)
            minorCount += 1
        }

        print("Default versions: \(versions)", inColor: .green, verbose: self.verbose)

        return versions
    }
}

extension PackageCollectionModel.V1.ProductType {
    init(from: PackageModel.ProductType) {
        switch from {
        case .library(let libraryType):
            self = .library(.init(from: libraryType))
        case .executable:
            self = .executable
        case .plugin:
            self = .plugin
        case .snippet:
            self = .snippet
        case .test:
            self = .test
        }
    }
}

extension PackageCollectionModel.V1.ProductType.LibraryType {
    init(from: PackageModel.ProductType.LibraryType) {
        switch from {
        case .static:
            self = .static
        case .dynamic:
            self = .dynamic
        case .automatic:
            self = .automatic
        }
    }
}
