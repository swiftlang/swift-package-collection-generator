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

import Foundation

import PackageModel

// Note: Not using SwiftPM's `PackageDescription` to avoid issues with
// different tools versions and we only need partial data.

/// Represents output of `swift package describe --type json`.
struct PackageDescription: Decodable {
    let name: String
    let targets: [Target]
    let products: [Product]
    let tools_version: String
    let platforms: [PlatformVersion]?

    struct Target: Decodable {
        let name: String
        let c99name: String
        let product_memberships: [String]?
    }

    struct Product: Decodable {
        let name: String
        let type: ProductType
        let targets: [String]
    }

    struct PlatformVersion: Decodable {
        let name: String
        let version: String
    }
}
