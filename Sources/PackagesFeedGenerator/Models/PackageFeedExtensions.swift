import PackageFeedModel

extension PackageFeed: CustomStringConvertible {
    public var description: String {
        """
        PackageFeed {
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

extension PackageFeed.Package: CustomStringConvertible {
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

extension PackageFeed.Package.Version: CustomStringConvertible {
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

extension PackageFeed.Package.Target: CustomStringConvertible {
    public var description: String {
        """
        Target(
                    name=\(self.name),
                    moduleName=\(self.moduleName.map { "\($0)" } ?? "nil")
                )
        """
    }
}

extension PackageFeed.Package.Product: CustomStringConvertible {
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

extension PackageFeed.Package.Platform: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension PackageFeed.Package.License: CustomStringConvertible {
    public var description: String {
        "License(\(self.name), \(self.url))"
    }
}
