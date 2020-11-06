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

import PackageCollectionModel

extension PackageCollection: CustomStringConvertible {
    public var description: String {
        """
        PackageCollection {
            title=\(self.title),
            overview=\(self.overview ?? "nil"),
            keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
            packages=\(self.packages),
            formatVersion=\(self.formatVersion),
            revision=\(self.revision.map { "\($0)" } ?? "nil"),
            generatedAt=\(self.generatedAt)
        }
        """
    }
}

extension PackageCollection.Package: CustomStringConvertible {
    public var description: String {
        """
        PackageMetadata {
            url=\(self.url),
            summary=\(self.summary ?? "nil"),
            versions=\(self.versions),
            readmeURL=\(self.readmeURL.map { "\($0)" } ?? "nil")
        }
        """
    }
}

extension PackageCollection.Package.Version: CustomStringConvertible {
    public var description: String {
        """
        Version {
                version=\(self.version),
                packageName=\(self.packageName),
                targets=\(self.targets),
                products=\(self.products),
                toolsVersion=\(self.toolsVersion),
                verifiedPlatforms=\(self.verifiedPlatforms.map { "\($0)" } ?? "nil"),
                verifiedSwiftVersions=\(self.verifiedSwiftVersions.map { "\($0)" } ?? "nil"),
                license=\(self.license.map { "\($0)" } ?? "nil")
            }
        """
    }
}

extension PackageCollection.Package.Target: CustomStringConvertible {
    public var description: String {
        """
        Target(
                    name=\(self.name),
                    moduleName=\(self.moduleName.map { "\($0)" } ?? "nil")
                )
        """
    }
}

extension PackageCollection.Package.Product: CustomStringConvertible {
    public var description: String {
        """
        Product(
                    name=\(self.name),
                    type=\(self.type),
                    targets=\(self.targets)
                )
        """
    }
}

extension PackageCollection.Package.Platform: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension PackageCollection.Package.License: CustomStringConvertible {
    public var description: String {
        "License(\(self.name), \(self.url))"
    }
}
