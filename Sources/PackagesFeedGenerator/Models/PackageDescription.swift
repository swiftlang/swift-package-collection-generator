//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Packages Feed Generator open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Packages Feed Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Packages Feed Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

// Note: Not using SwiftPM's `PackageDescription` to avoid issues with
// different tools versions and we only need partial data.

/// Represents output of `swift package describe --type json`.
struct PackageDescription: Decodable {
    let name: String
    let targets: [Target]

    struct Target: Decodable {
        let name: String
        let c99name: String
    }
}
