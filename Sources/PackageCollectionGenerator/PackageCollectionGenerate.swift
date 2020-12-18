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

import ArgumentParser
import Foundation
import PackageCollections
import TSCBasic
import TSCUtility
import Utilities

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

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool = false

    typealias Model = JSONPackageCollectionModel.V1

    public init() {}

    public func run() throws {
        Process.verbose = self.verbose

        print("Using input file located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        // Get the list of packages to process
        let jsonDecoder = JSONDecoder()
        let input = try jsonDecoder.decode(PackageCollectionGeneratorInput.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))
        print("\(input)", verbose: self.verbose)

        // Generate metadata for each package
        let packages: [Model.Collection.Package] = input.packages.compactMap { package in
            do {
                let packageMetadata = try self.generateMetadata(for: package, jsonDecoder: jsonDecoder)
                print("\(packageMetadata)", verbose: self.verbose)
                return packageMetadata
            } catch {
                printError("Failed to generate package metadata: \(error)")
                return nil
            }
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

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        if #available(macOS 10.15, *) {
            #if os(macOS)
            jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            #else
            jsonEncoder.outputFormatting = [.sortedKeys]
            #endif
        }

        // Make sure the output directory exists
        let outputDirectory = AbsolutePath(outputPath).parentDirectory
        try localFileSystem.createDirectory(outputDirectory, recursive: true)

        // Write the package collection
        let jsonData = try jsonEncoder.encode(packageCollection)
        try jsonData.write(to: URL(fileURLWithPath: self.outputPath))
        print("Package collection saved to \(self.outputPath)", inColor: .cyan, verbose: self.verbose)
    }

    private func generateMetadata(
        for package: PackageCollectionGeneratorInput.Package,
        jsonDecoder: JSONDecoder
    ) throws -> Model.Collection.Package {
        print("Processing Package(\(package.url))", inColor: .cyan, verbose: self.verbose)

        // Try to locate the directory where the repository might have been cloned to previously
        if let workingDirectoryPath = self.workingDirectoryPath {
            // Extract directory name from repository URL
            let repositoryURL = package.url.absoluteString
            let regex = try NSRegularExpression(pattern: "([^/]+)\\.git$", options: .caseInsensitive)

            if let match = regex.firstMatch(in: repositoryURL, options: [], range: NSRange(location: 0, length: repositoryURL.count)) {
                if let range = Range(match.range(at: 1), in: repositoryURL) {
                    let repositoryName = String(repositoryURL[range])
                    print("Extracted repository name from URL: \(repositoryName)", inColor: .green, verbose: self.verbose)

                    let gitDirectoryPath = AbsolutePath(workingDirectoryPath).appending(component: repositoryName)
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
                        jsonDecoder: jsonDecoder
                    )
                }
            }
        }

        // Fallback to tmp directory if we cannot use the working directory for some reason or it's unspecified
        return try withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // Clone the package repository
            try GitUtilities.clone(package.url.absoluteString, to: tmpDir)

            return try self.generateMetadata(
                for: package,
                gitDirectoryPath: tmpDir,
                jsonDecoder: jsonDecoder
            )
        }
    }

    private func generateMetadata(
        for package: PackageCollectionGeneratorInput.Package,
        gitDirectoryPath: AbsolutePath,
        jsonDecoder: JSONDecoder
    ) throws -> Model.Collection.Package {
        // Select versions if none specified
        let versions = try package.versions ?? self.defaultVersions(for: gitDirectoryPath)
        // Load the manifest for each version and extract metadata
        let packageVersions: [Model.Collection.Package.Version] = versions.compactMap { version in
            do {
                return try self.generateMetadata(
                    for: version,
                    excludedProducts: package.excludedProducts.map { Set($0) } ?? [],
                    excludedTargets: package.excludedTargets.map { Set($0) } ?? [],
                    gitDirectoryPath: gitDirectoryPath,
                    jsonDecoder: jsonDecoder
                )
            } catch {
                printError("Failed to load package manifest for version \(version): \(error)")
                return nil
            }
        }
        return Model.Collection.Package(
            url: package.url,
            summary: package.summary,
            keywords: package.keywords,
            versions: packageVersions,
            readmeURL: package.readmeURL,
            license: nil
        )
    }

    private func generateMetadata(
        for version: String,
        excludedProducts: Set<String>,
        excludedTargets: Set<String>,
        gitDirectoryPath: AbsolutePath,
        jsonDecoder: JSONDecoder
    ) throws -> Model.Collection.Package.Version {
        // Check out the git tag
        print("Checking out version \(version)", inColor: .yellow, verbose: self.verbose)
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "checkout", version)

        // Run `swift package dump-package` to generate JSON manifest from `Package.swift`
        let manifestJSON = try ShellUtilities.run(ShellUtilities.shell, "-c", "cd \(gitDirectoryPath) && swift package dump-package")
        let manifest = try jsonDecoder.decode(PackageManifest.self, from: manifestJSON.data(using: .utf8) ?? Data())

        // Run `swift package describe --type json` to generate JSON package description
        let packageDescriptionJSON = try ShellUtilities.run(ShellUtilities.shell, "-c", "cd \(gitDirectoryPath) && swift package describe --type json")
        let packageDescription = try jsonDecoder.decode(PackageDescription.self, from: packageDescriptionJSON.data(using: .utf8) ?? Data())
        let targetModuleNames = packageDescription.targets.reduce(into: [String: String]()) { result, target in
            result[target.name] = target.c99name
        }

        let products: [Model.Product] = manifest.products
            .filter { !excludedProducts.contains($0.name) }
            .map { product in
                Model.Product(
                    name: product.name,
                    type: product.type,
                    targets: product.targets
                )
            }

        // Include only packages that are in at least one product
        let publicTargets = Set(products.map { $0.targets }.reduce(into: []) { result, targets in
            result.append(contentsOf: targets.filter { !excludedTargets.contains($0) })
        })

        var minimumPlatformVersions: [Model.PlatformVersion]?
        if let platforms = manifest.platforms, !platforms.isEmpty {
            minimumPlatformVersions = platforms.map { Model.PlatformVersion(name: $0.platformName, version: $0.version) }
        }

        return Model.Collection.Package.Version(
            version: version,
            packageName: manifest.name,
            targets: manifest.targets.filter { publicTargets.contains($0.name) }.map { target in
                Model.Target(
                    name: target.name,
                    moduleName: targetModuleNames[target.name]
                )
            },
            products: products,
            toolsVersion: manifest.toolsVersion._version,
            minimumPlatformVersions: minimumPlatformVersions,
            verifiedCompatibility: nil,
            license: nil
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
        var allVersions = tags.compactMap { Version(string: $0) }
        allVersions.sort(by: >)

        var versions = [String]()
        var currentMajor: Int?
        var majorCount = 0
        var minorCount = 0
        for version in allVersions {
            if version.major != currentMajor {
                currentMajor = version.major
                majorCount += 1
                minorCount = 0
            }

            guard majorCount <= 2 else { break }
            guard minorCount < 3 else { continue }

            versions.append(version.description)
            minorCount += 1
        }

        print("Default versions: \(versions)", inColor: .green, verbose: self.verbose)

        return versions
    }
}
