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

/// Package collection
public struct PackageCollection: Equatable, Codable {
    /// The package collection's title
    public let title: String

    /// An overview or description of the package collection
    public let overview: String?

    /// Keywords associated with the package collection
    public let keywords: [String]?

    /// A list of packages (metadata)
    public let packages: [Package]

    /// The format version that the package collection conforms to
    public let formatVersion: FormatVersion

    /// The revision number of this package collection
    public let revision: Int?

    /// Timestamp at which the package collection was generated (ISO-8601 format)
    public let generatedAt: Date

    /// Creates a `PackageCollection`
    public init(
        title: String,
        overview: String? = nil,
        keywords: [String]? = nil,
        packages: [Package],
        formatVersion: FormatVersion,
        revision: Int? = nil,
        generatedAt: Date = Date()
    ) {
        self.title = title
        self.overview = overview
        self.keywords = keywords
        self.packages = packages
        self.formatVersion = formatVersion
        self.revision = revision
        self.generatedAt = generatedAt
    }

    /// Representation of `PackageCollection` JSON schema version
    public enum FormatVersion: String, Codable {
        case v1_0 = "1.0"
    }
}

extension PackageCollection {
    /// Package metadata
    public struct Package: Equatable, Codable {
        /// URL of the package. For now only Git repository URLs are supported.
        public let url: URL

        /// A summary or description of what the package does, etc.
        public let summary: String?

        /// A selected list of package versions
        public let versions: [Version]

        /// URL of the package's README
        public let readmeURL: URL?

        /// Creates a `Package`
        public init(
            url: URL,
            summary: String? = nil,
            versions: [Version],
            readmeURL: URL? = nil
        ) {
            self.url = url
            self.summary = summary
            self.versions = versions
            self.readmeURL = readmeURL
        }
    }
}

extension PackageCollection.Package {
    /// Package version metadata
    public struct Version: Equatable, Codable {
        /// Semantic version string
        public let version: String

        /// Name of the package
        public let packageName: String

        /// Package version's targets
        public let targets: [Target]

        /// Package version's products
        public let products: [Product]

        /// The tools version used by the package version
        public let toolsVersion: String

        /// Package version's **verified** platforms
        public let verifiedPlatforms: [Platform]?

        /// Package version's **verified** Swift versions
        public let verifiedSwiftVersions: [String]?

        /// Package version's license
        public let license: License?

        /// Creates a `Version`
        public init(
            version: String,
            packageName: String,
            targets: [Target],
            products: [Product],
            toolsVersion: String,
            verifiedPlatforms: [Platform]? = nil,
            verifiedSwiftVersions: [String]? = nil,
            license: License? = nil
        ) {
            self.version = version
            self.packageName = packageName
            self.targets = targets
            self.products = products
            self.toolsVersion = toolsVersion
            self.verifiedPlatforms = verifiedPlatforms
            self.verifiedSwiftVersions = verifiedSwiftVersions
            self.license = license
        }
    }

    /// Package target
    public struct Target: Equatable, Codable {
        /// Target name
        public let name: String

        /// The module name if this target can be imported as a module
        public let moduleName: String?

        /// Creates a `Target`
        public init(name: String, moduleName: String? = nil) {
            self.name = name
            self.moduleName = moduleName
        }
    }

    /// Package product
    public struct Product: Equatable, Codable {
        /// Product name
        public let name: String

        /// Product type
        public let type: ProductType

        /// Product's targets
        public let targets: [String]

        /// Creates a `Product`
        public init(
            name: String,
            type: ProductType,
            targets: [String]
        ) {
            self.name = name
            self.type = type
            self.targets = targets
        }
    }

    /// Platform
    public struct Platform: Equatable, Codable {
        /// Platform name (e.g., macOS, Linux, etc.)
        public let name: String

        /// Creates a `Platform`
        public init(name: String) {
            self.name = name
        }
    }

    /// License
    public struct License: Equatable, Codable {
        /// License name (e.g., Apache-2.0, MIT, etc.)
        public let name: String

        /// URL to the license file
        public let url: URL

        /// Creates a `License`
        public init(name: String, url: URL) {
            self.name = name
            self.url = url
        }
    }
}
