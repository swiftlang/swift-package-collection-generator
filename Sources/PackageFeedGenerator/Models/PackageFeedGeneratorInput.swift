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

/// Input for the `package-feed-generate` command
struct PackageFeedGeneratorInput: Equatable, Codable, CustomStringConvertible {
    /// The package feed's title
    let title: String

    /// An overview or description of the package feed
    let overview: String?

    /// Keywords associated with the package feed
    let keywords: [String]?

    /// A list of packages to process
    let packages: [Package]

    init(
        title: String,
        overview: String? = nil,
        keywords: [String]? = nil,
        packages: [Package]
    ) {
        self.title = title
        self.overview = overview
        self.keywords = keywords
        self.packages = packages
    }

    var description: String {
        """
        PackageFeedGeneratorInput {
            title=\(self.title),
            overview=\(self.overview ?? "nil"),
            keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
            packages=\(self.packages)
        }
        """
    }
}

extension PackageFeedGeneratorInput {
    /// Represents a package to be processed
    struct Package: Equatable, Codable, CustomStringConvertible {
        /// URL of the package. For now only Git repository URLs are supported.
        let url: URL

        /// A summary or description of what the package does, etc.
        let summary: String?

        /// A list of package versions to include.
        /// If not specified, the generator will select from most recent semvers.
        let versions: [String]?

        /// Products to be excluded from the feed
        let excludedProducts: [String]?

        /// Targets to be excluded from the feed
        let excludedTargets: [String]?

        var description: String {
            """
            Package {
                    url=\(self.url),
                    summary=\(self.summary ?? "nil"),
                    versions=\(self.versions.map { "\($0)" } ?? "nil"),
                    excludedProducts=\(self.excludedProducts.map { "\($0)" } ?? "nil"),
                    excludedTargets=\(self.excludedTargets.map { "\($0)" } ?? "nil")
                }
            """
        }
    }
}
