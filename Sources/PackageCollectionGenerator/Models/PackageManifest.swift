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

import PackageModel

// Note: Not using SwiftPM's `PackageModel.Manifest` to avoid issues with
// different tools versions and we only need partial data.

/// JSON representation of `Package.swift`; output of `swift package dump-package`.
struct PackageManifest: Decodable {
    let name: String
    let targets: [Target]
    let products: [Product]
    let toolsVersion: ToolsVersion
    let platforms: [PlatformVersion]?

    struct Target: Decodable {
        let name: String
    }

    struct Product: Decodable {
        let name: String
        let type: ProductType
        let targets: [String]
    }

    struct ToolsVersion: Decodable {
        let _version: String
    }

    struct PlatformVersion: Decodable {
        let platformName: String
        let version: String
    }
}
