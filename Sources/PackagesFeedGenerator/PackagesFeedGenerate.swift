import ArgumentParser
import Foundation
import PackageFeedModel
import TSCBasic
import TSCUtility
import Utilities

public struct PackagesFeedGenerate: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Generate a package feed from the given list of packages."
    )

    @Argument(help: "The path to the JSON document containing the list of packages to be processed")
    private var inputPath: String

    @Argument(help: "The path to write the generated package feed to")
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

    @Option(help: "The revision number of the generated package feed")
    private var revision: Int?

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool = false

    public init() {}

    public func run() throws {
        Process.verbose = self.verbose

        print("Using input file located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        // Get the list of packages to process
        let jsonDecoder = JSONDecoder()
        let input = try jsonDecoder.decode(PackagesFeedGeneratorInput.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))
        print("\(input)", verbose: self.verbose)

        // Generate metadata for each package
        let packages: [PackageFeed.Package] = input.packages.compactMap { package in
            do {
                let packageMetadata = try self.generateMetadata(for: package, jsonDecoder: jsonDecoder)
                print("\(packageMetadata)", verbose: self.verbose)
                return packageMetadata
            } catch {
                printError("Failed to generate package metadata: \(error)")
                return nil
            }
        }
        // Construct the package feed
        let packageFeed = PackageFeed(
            title: input.title,
            overview: input.overview,
            keywords: input.keywords ?? [],
            packages: packages,
            formatVersion: .v1_0,
            revision: self.revision,
            generatedAt: Date()
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

        // Write the package feed
        let jsonData = try jsonEncoder.encode(packageFeed)
        try jsonData.write(to: URL(fileURLWithPath: self.outputPath))
        print("Package feed saved to \(self.outputPath)", inColor: .cyan, verbose: self.verbose)
    }

    private func generateMetadata(
        for package: PackagesFeedGeneratorInput.Package,
        jsonDecoder: JSONDecoder
    ) throws -> PackageFeed.Package {
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

                    let gitDirectoryPath = URL(fileURLWithPath: workingDirectoryPath).appendingPathComponent(repositoryName).path
                    if localFileSystem.exists(AbsolutePath(gitDirectoryPath)) {
                        // If directory exists, assume it has been cloned previously
                        print("\(gitDirectoryPath) exists", inColor: .yellow, verbose: self.verbose)
                        try self.gitFetch(repositoryURL, at: gitDirectoryPath)
                    } else {
                        // Else clone it
                        print("\(gitDirectoryPath) does not exist", inColor: .yellow, verbose: self.verbose)
                        try self.gitClone(repositoryURL, to: gitDirectoryPath)
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
            let tmpDirPath = tmpDir.pathString

            // Clone the package repository
            try self.gitClone(package.url.absoluteString, to: tmpDirPath)

            return try self.generateMetadata(
                for: package,
                gitDirectoryPath: tmpDirPath,
                jsonDecoder: jsonDecoder
            )
        }
    }

    private func generateMetadata(
        for package: PackagesFeedGeneratorInput.Package,
        gitDirectoryPath: String,
        jsonDecoder: JSONDecoder
    ) throws -> PackageFeed.Package {
        // Select versions if none specified
        let versions = try package.versions ?? self.defaultVersions(for: gitDirectoryPath)
        // Load the manifest for each version and extract metadata
        let packageVersions: [PackageFeed.Package.Version] = versions.compactMap { version in
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
        return PackageFeed.Package(
            url: package.url,
            summary: package.summary,
            versions: packageVersions,
            readmeURL: nil
        )
    }

    private func generateMetadata(
        for version: String,
        excludedProducts: Set<String>,
        excludedTargets: Set<String>,
        gitDirectoryPath: String,
        jsonDecoder: JSONDecoder
    ) throws -> PackageFeed.Package.Version {
        // Check out the git tag
        print("Checking out version \(version)", inColor: .yellow, verbose: self.verbose)
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath, "checkout", version)

        // Run `swift package dump-package` to generate JSON manifest from `Package.swift`
        let manifestJSON = try ShellUtilities.run(ShellUtilities.shell, "-c", "cd \(gitDirectoryPath) && swift package dump-package")
        let manifest = try jsonDecoder.decode(PackageManifest.self, from: manifestJSON.data(using: .utf8) ?? Data())

        // Run `swift package describe --type json` to generate JSON package description
        let packageDescriptionJSON = try ShellUtilities.run(ShellUtilities.shell, "-c", "cd \(gitDirectoryPath) && swift package describe --type json")
        // This is secondary data source so we allow errors
        let packageDescription = try? jsonDecoder.decode(PackageDescription.self, from: packageDescriptionJSON.data(using: .utf8) ?? Data())
        let targetModuleNames = packageDescription?.targets.reduce(into: [String: String]()) { result, target in
            result[target.name] = target.c99name
        } ?? [:]

        let products: [PackageFeed.Package.Product] = manifest.products
            .filter { !excludedProducts.contains($0.name) }
            .map { product in
                PackageFeed.Package.Product(
                    name: product.name,
                    type: product.type,
                    targets: product.targets
                )
            }

        // Include only packages that are in at least one product
        let publicTargets = Set(products.map { $0.targets }.reduce(into: []) { result, targets in
            result.append(contentsOf: targets.filter { !excludedTargets.contains($0) })
        })

        return PackageFeed.Package.Version(
            version: version,
            packageName: manifest.name,
            targets: manifest.targets.filter { publicTargets.contains($0.name) }.map { target in
                PackageFeed.Package.Target(
                    name: target.name,
                    moduleName: targetModuleNames[target.name]
                )
            },
            products: products,
            toolsVersion: manifest.toolsVersion._version,
            verifiedPlatforms: nil,
            verifiedSwiftVersions: nil,
            license: nil
        )
    }

    private func gitClone(_ repositoryURL: String, to path: String) throws {
        try ShellUtilities.run(Git.tool, "clone", repositoryURL, path)
    }

    private func gitFetch(_ repositoryURL: String, at gitDirectoryPath: String) throws {
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath, "fetch")
    }

    private func defaultVersions(for gitDirectoryPath: String) throws -> [String] {
        // List all the tags
        let output = try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath, "tag")
        let tags = output.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
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
