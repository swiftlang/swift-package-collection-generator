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

import Basics
import TSCUtility

public enum GitUtilities {
    public static func clone(_ repositoryURL: String, to path: AbsolutePath) throws {
        try ShellUtilities.run(Git.tool, "clone", repositoryURL, path.pathString, "--recurse-submodules")
    }

    public static func fetch(_ repositoryURL: String, at gitDirectoryPath: AbsolutePath) throws {
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "fetch")
    }

    public static func checkout(_ reference: String, at gitDirectoryPath: AbsolutePath) throws {
        try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "checkout", reference)
    }

    public static func listTags(for gitDirectoryPath: AbsolutePath) throws -> [String] {
        let output = try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "tag")
        let tags = output.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return tags
    }

    public static func tagInfo(_ tag: String, for gitDirectoryPath: AbsolutePath) throws -> GitTagInfo? {
        // If a tag is annotated (i.e., has a message), this command will return "tag", otherwise it will return "commit".
        let tagType = try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "cat-file", "-t", tag).trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagType == "tag" else {
            return nil
        }
        // The following commands only make sense for annotated tag. Otherwise, `contents` would be
        // the message of the commit that the tag points to, which isn't always appropriate, and
        // `taggerdate` would be empty
        let message = try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "tag", "-l", "--format=%(contents:subject)", tag).trimmingCharacters(in: .whitespacesAndNewlines)
        // This shows the date when the tag was created. This would be empty if the tag was created on GitHub as part of a release.
        let createdAt = try ShellUtilities.run(Git.tool, "-C", gitDirectoryPath.pathString, "tag", "-l", "%(taggerdate:iso8601-strict)", tag).trimmingCharacters(in: .whitespacesAndNewlines)
        return GitTagInfo(message: message, createdAt: createdAt)
    }
}

public struct GitTagInfo {
    public let message: String
    public let createdAt: Date?

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()

    init(message: String, createdAt: String) {
        self.message = message
        self.createdAt = Self.dateFormatter.date(from: createdAt)
    }
}

public struct GitURL {
    public let host: String
    public let owner: String
    public let repository: String

    public static func from(_ initialGitURL: String) -> GitURL? {
        let gitURL: String
        if initialGitURL.suffix(4).lowercased() == ".git" {
            gitURL = String(initialGitURL.dropLast(4))
        } else {
            gitURL = initialGitURL
        }

        do {
            let regex = try NSRegularExpression(pattern: #"([^/@]+)[:/]([^:/]+)/([^/]+)$"#, options: .caseInsensitive)
            if let match = regex.firstMatch(in: gitURL, options: [], range: NSRange(location: 0, length: gitURL.count)) {
                if let hostRange = Range(match.range(at: 1), in: gitURL),
                   let ownerRange = Range(match.range(at: 2), in: gitURL),
                   let repoRange = Range(match.range(at: 3), in: gitURL) {
                    let host = String(gitURL[hostRange])
                    let owner = String(gitURL[ownerRange])
                    let repository = String(gitURL[repoRange])

                    return GitURL(host: host, owner: owner, repository: repository)
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
