//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

import PackageCollectionsModel

/// Input for the `package-collection-generate` command
public struct PackageCollectionGeneratorInput: Equatable, Codable {
    /// The name of the package collection, for display purposes only.
    public let name: String

    /// A description of the package collection.
    public let overview: String?

    /// An array of keywords that the collection is associated with.
    public let keywords: [String]?

    /// A list of packages to process.
    public let packages: [Package]

    /// The author of this package collection.
    public let author: PackageCollectionModel.V1.Collection.Author?

    public init(
        name: String,
        overview: String? = nil,
        keywords: [String]? = nil,
        packages: [Package],
        author: PackageCollectionModel.V1.Collection.Author? = nil
    ) {
        self.name = name
        self.overview = overview
        self.keywords = keywords
        self.packages = packages
        self.author = author
    }
}

extension PackageCollectionGeneratorInput: CustomStringConvertible {
    public var description: String {
        """
        PackageCollectionGeneratorInput {
            name=\(self.name),
            overview=\(self.overview ?? "nil"),
            keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
            packages=\(self.packages),
            author=\(self.author.map { "\($0)" } ?? "nil")
        }
        """
    }
}

extension PackageCollectionGeneratorInput {
    /// Represents a package to be processed
    public struct Package: Equatable, Codable {
        /// The URL of the package. Currently only Git repository URLs are supported.
        public let url: URL

        /// A description of the package.
        public let summary: String?

        /// An array of keywords that the package is associated with.
        public let keywords: [String]?

        /// A list of package versions to include.
        /// If not specified, the generator will select from most recent SemVers.
        public let versions: [String]?

        /// Products to be excluded from the collection.
        public let excludedProducts: [String]?

        /// Targets to be excluded from the collection.
        public let excludedTargets: [String]?

        /// The URL of the package's README.
        public let readmeURL: URL?

        public init(
            url: URL,
            summary: String? = nil,
            keywords: [String]? = nil,
            versions: [String]? = nil,
            excludedProducts: [String]? = nil,
            excludedTargets: [String]? = nil,
            readmeURL: URL? = nil
        ) {
            self.url = url
            self.summary = summary
            self.keywords = keywords
            self.versions = versions
            self.excludedProducts = excludedProducts
            self.excludedTargets = excludedTargets
            self.readmeURL = readmeURL
        }
    }
}

extension PackageCollectionGeneratorInput.Package: CustomStringConvertible {
    public var description: String {
        """
        Package {
                url=\(self.url),
                summary=\(self.summary ?? "nil"),
                keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
                versions=\(self.versions.map { "\($0)" } ?? "nil"),
                excludedProducts=\(self.excludedProducts.map { "\($0)" } ?? "nil"),
                excludedTargets=\(self.excludedTargets.map { "\($0)" } ?? "nil"),
                readmeURL=\(self.readmeURL.map { "\($0)" } ?? "nil")
            }
        """
    }
}
