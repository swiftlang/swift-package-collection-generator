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
import TSCBasic
import TSCUtility

public enum GitUtilities {
    public static func clone(_ repositoryURL: String, to path: AbsolutePath) throws {
        try ShellUtilities.run(Git.tool, "clone", repositoryURL, path.pathString)
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
}
