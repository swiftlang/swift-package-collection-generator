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
        guard let baseURL: URL = self.apiURL(packageURL) else {
            return callback(.failure(Errors.invalidGitURL(packageURL)))
        }

        // get the main data
        let metadataHeaders = HTTPClientHeaders()
        let metadataOptions = self.makeRequestOptions(validResponseCodes: [200, 401, 403, 404])
        let hasAuthorization = metadataOptions.authorizationProvider?(baseURL) != nil
        var result: Result<HTTPClient.Response, Error> = tsc_await { callback in self.httpClient.get(baseURL, headers: metadataHeaders, options: metadataOptions, completion: callback) }

        if case .success(let response) = result {
            let apiLimit = response.headers.get("RateLimit-Limit").first.flatMap(Int.init) ?? -1
            let apiRemaining = response.headers.get("RateLimit-Remaining").first.flatMap(Int.init) ?? -1
            switch (response.statusCode, hasAuthorization, apiRemaining) {
            case (_, _, 0):
                result = .failure(Errors.apiLimitsExceeded(baseURL, apiLimit, apiRemaining))
            case (401, true, _):
                result = .failure(Errors.invalidAuthToken(baseURL))
            case (401, false, _):
                result = .failure(Errors.permissionDenied(baseURL))
            case (403, _, _):
                result = .failure(Errors.permissionDenied(baseURL))
            case (404, _, _):
                result = .failure(Errors.notFound(baseURL))
            case (200, _, _):
                guard let metadata = try? response.decodeBody(GetProjectResponse.self, using: self.decoder) else {
                    callback(.failure(Errors.invalidResponse(baseURL, "Invalid body")))
                    return
                }

                let license = metadata.license
                let packageLicense: PackageCollectionModel.V1.License?
                if let licenseURL = metadata.licenseURL,
                   let licenseURL = URL(string: licenseURL) {
                    packageLicense = .init(name: license?.key, url: licenseURL)
                } else {
                    packageLicense = nil
                }

                let model = PackageBasicMetadata(
                    summary: metadata.description,
                    keywords: metadata.topics,
                    readmeURL: metadata.readmeURL.flatMap { URL(string: $0) },
                    license: packageLicense
                )

                callback(.success(model))
            default:
                callback(.failure(Errors.invalidResponse(baseURL, "Invalid status code: \(response.statusCode)")))
            }
        }
    }

    internal func apiURL(_ url: URL) -> Foundation.URL? {
        guard let baseURL = URL(string: url.absoluteString.spm_dropGitSuffix()),
              let urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let scheme = urlComponents.scheme,
              let host = urlComponents.host else {
            return nil
        }
        let projectPath = urlComponents.path.dropFirst().replacingOccurrences(of: "/", with: "%2F")
        let apiPrefix = GitLabPackageMetadataProvider.apiHostURLPathPostfix
        let metadataURL = URL(string: "\(scheme)://\(host)/\(apiPrefix)/projects/\(projectPath)")!
        return metadataURL
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
    fileprivate struct GetProjectResponse: Codable {
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
        let key: String?

        private enum CodingKeys: String, CodingKey {
            case htmlURL = "html_url"
            case sourceURL = "source_url"
            case key
        }
    }
}
