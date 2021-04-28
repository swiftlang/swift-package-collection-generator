//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

import PackageCollectionsModel

protocol PackageMetadataProvider {
    func get(_ packageURL: URL, callback: @escaping (Result<PackageBasicMetadata, Error>) -> Void)
}

enum AuthTokenType: Hashable, CustomStringConvertible {
    case github(_ host: String)

    var description: String {
        switch self {
        case .github(let host):
            return "github(\(host))"
        }
    }

    static func from(type: String, host: String) -> AuthTokenType? {
        switch type {
        case "github":
            return .github(host)
        default:
            return nil
        }
    }
}

struct PackageBasicMetadata: Equatable {
    let summary: String?
    let keywords: [String]?
    let readmeURL: URL?
    let license: PackageCollectionModel.V1.License?
}

// MARK: - Utility

extension Result {
    var failure: Failure? {
        switch self {
        case .failure(let failure):
            return failure
        case .success:
            return nil
        }
    }

    var success: Success? {
        switch self {
        case .failure:
            return nil
        case .success(let value):
            return value
        }
    }
}
