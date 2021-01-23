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

import PackageCollectionsModel

extension PackageCollectionModel.V1.Collection: CustomStringConvertible {
    public var description: String {
        """
        Collection {
            name=\(self.name),
            overview=\(self.overview ?? "nil"),
            keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
            packages=\(self.packages),
            formatVersion=\(self.formatVersion),
            revision=\(self.revision.map { "\($0)" } ?? "nil"),
            generatedAt=\(self.generatedAt),
            generatedBy=\(self.generatedBy.map { "\($0)" } ?? "nil")
        }
        """
    }
}

extension PackageCollectionModel.V1.Collection.Author: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension PackageCollectionModel.V1.Collection.Package: CustomStringConvertible {
    public var description: String {
        """
        Package {
            url=\(self.url),
            summary=\(self.summary ?? "nil"),
            keywords=\(self.keywords.map { "\($0)" } ?? "nil"),
            versions=\(self.versions),
            readmeURL=\(self.readmeURL.map { "\($0)" } ?? "nil"),
            license=\(self.license.map { "\($0)" } ?? "nil")
        }
        """
    }
}

extension PackageCollectionModel.V1.Collection.Package.Version: CustomStringConvertible {
    public var description: String {
        """
        Version {
                version=\(self.version),
                packageName=\(self.packageName),
                targets=\(self.targets),
                products=\(self.products),
                toolsVersion=\(self.toolsVersion),
                minimumPlatformVersions=\(self.minimumPlatformVersions.map { "\($0)" } ?? "nil"),
                verifiedCompatibility=\(self.verifiedCompatibility.map { "\($0)" } ?? "nil"),
                license=\(self.license.map { "\($0)" } ?? "nil")
            }
        """
    }
}

extension PackageCollectionModel.V1.Target: CustomStringConvertible {
    public var description: String {
        """
        Target(
                    name=\(self.name),
                    moduleName=\(self.moduleName.map { "\($0)" } ?? "nil")
                )
        """
    }
}

extension PackageCollectionModel.V1.Product: CustomStringConvertible {
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

extension PackageCollectionModel.V1.PlatformVersion: CustomStringConvertible {
    public var description: String {
        "\(self.name)(\(self.version))"
    }
}

extension PackageCollectionModel.V1.Compatibility: CustomStringConvertible {
    public var description: String {
        "(\(self.platform), \(self.swiftVersion))"
    }
}

extension PackageCollectionModel.V1.Platform: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension PackageCollectionModel.V1.License: CustomStringConvertible {
    public var description: String {
        "License(\(self.url)\(self.name.map { ", \($0)" } ?? ""))"
    }
}
