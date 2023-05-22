//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2021-2023 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Basics
import Foundation

public func ensureAbsolute(path: String) throws -> AbsolutePath {
    do {
        return try AbsolutePath(validating: path)
    } catch {
        return try AbsolutePath(
            validating: path,
            relativeTo: AbsolutePath(validating: FileManager.default.currentDirectoryPath)
        )
    }
}
