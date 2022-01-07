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

import Dispatch
import Foundation

import TSCBasic
import Basics
import PackageCollectionsModel
import Utilities

struct GitLabPackageMetadataProvider: PackageMetadataProvider {
    private static let apiHostURLPathPostfix = "api/v4"

    private let authTokens: [AuthTokenType: String]
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder
    private enum ResultKeys {
        case metadata
    }

    init(authTokens: [AuthTokenType: String] = [:], httpClient: HTTPClient? = nil) {
        self.authTokens = authTokens
        self.httpClient = httpClient ?? Self.makeDefaultHTTPClient()
        self.decoder = JSONDecoder.makeWithDefaults()
    }

    func get(_ packageURL: URL, callback: @escaping (Result<PackageBasicMetadata, Error>) -> Void) {
        guard let baseURL = self.apiURL(packageURL.absoluteString),
              let urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                  return callback(.failure(Errors.invalidGitURL(packageURL)))
              }

        let projectPath = urlComponents.path.dropFirst().replacingOccurrences(of: "/", with: "%2F")
        let apiPrefix = GitLabPackageMetadataProvider.apiHostURLPathPostfix
        let metadataURL = URL(string: "\(urlComponents.scheme!)://\(urlComponents.host!)/\(apiPrefix)/projects/\(projectPath)")!

        // get the main data
        let metadataHeaders = HTTPClientHeaders()
        let metadataOptions = self.makeRequestOptions(validResponseCodes: [200, 401, 403, 404])
        let hasAuthorization = metadataOptions.authorizationProvider?(metadataURL) != nil
        var result: Result<HTTPClient.Response, Error> = tsc_await { callback in self.httpClient.get(metadataURL, headers: metadataHeaders, options: metadataOptions, completion: callback) }

        if case .success(let response) = result {
            let apiLimit = response.headers.get("RateLimit-Limit").first.flatMap(Int.init) ?? -1
            let apiRemaining = response.headers.get("RateLimit-Remaining").first.flatMap(Int.init) ?? -1
            switch (response.statusCode, hasAuthorization, apiRemaining) {
            case (_, _, 0):
                result = .failure(Errors.apiLimitsExceeded(metadataURL, apiLimit, apiRemaining))
            case (401, true, _):
                result = .failure(Errors.invalidAuthToken(metadataURL))
            case (401, false, _):
                result = .failure(Errors.permissionDenied(metadataURL))
            case (403, _, _):
                result = .failure(Errors.permissionDenied(metadataURL))
            case (404, _, _):
                result = .failure(Errors.notFound(metadataURL))
            case (200, _, _):
                guard let metadata = try? response.decodeBody(GetRepositoryResponse.self, using: self.decoder) else {
                    callback(.failure(Errors.invalidResponse(metadataURL, "Invalid body")))
                    return
                }

                let license = metadata.license
                let packageLicense: PackageCollectionModel.V1.License?
                if let license = license {
                    packageLicense = .init(name: license.name, url: license.sourceURL)
                } else if let licenseURL = metadata.license_url,
                    let licenseURL = URL(string: licenseURL) {
                    packageLicense = .init(name: nil, url: licenseURL)
                } else {
                    packageLicense = nil
                }

                let model = PackageBasicMetadata(
                    summary: metadata.description,
                    keywords: metadata.topics,
                    readmeURL: metadata.readme_url.flatMap { URL(string: $0) },
                    license: packageLicense
                )

                callback(.success(model))
            default:
                callback(.failure(Errors.invalidResponse(metadataURL, "Invalid status code: \(response.statusCode)")))
            }
        }
    }

    internal func apiURL(_ url: String) -> Foundation.URL? {
        return URL(string: url.spm_dropGitSuffix())
    }

    private func makeRequestOptions(validResponseCodes: [Int]) -> HTTPClientRequest.Options {
        var options = HTTPClientRequest.Options()
        options.addUserAgent = true
        options.validResponseCodes = validResponseCodes
        options.authorizationProvider = { url in
            url.host.flatMap { host in
                return self.authTokens[.gitlab(host)].flatMap { token in "Bearer \(token)" }
            }
        }
        return options
    }

    private static func makeDefaultHTTPClient() -> HTTPClient {
        var client = HTTPClient()
        client.configuration.requestTimeout = .seconds(2)
        client.configuration.retryStrategy = .exponentialBackoff(maxAttempts: 3, baseDelay: .milliseconds(50))
        client.configuration.circuitBreakerStrategy = .hostErrors(maxErrors: 50, age: .seconds(30))
        return client
    }

    enum Errors: Error, Equatable {
        case invalidGitURL(URL)
        case invalidResponse(URL, String)
        case permissionDenied(URL)
        case invalidAuthToken(URL)
        case apiLimitsExceeded(URL, Int, Int)
        case notFound(URL)
    }
}

extension GitLabPackageMetadataProvider {
    fileprivate struct GetRepositoryResponse: Codable {
        let name: String
        let fullName: String
        let description: String?
        let topics: [String]?
        let licenseURL: String?
        let readmeURL: String?
        let license: License?

        private enum CodingKeys: String, CodingKey {
            case name
            case fullName = "name_with_namespace"
            case description
            case topics
            case license_url
            case readme_url
            case license
        }
    }
}

extension GitLabPackageMetadataProvider {
    fileprivate struct License: Codable {
        let htmlURL: Foundation.URL
        let sourceURL: Foundation.URL
        let nickname: String?
        let name: String?

        private enum CodingKeys: String, CodingKey {
            case htmlURL = "html_url"
            case sourceURL = "source_url"
            case nickname
            case name
        }
    }
}
