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

import Dispatch
import Foundation

import Basics
import PackageCollectionsModel
import Utilities

struct GitHubPackageMetadataProvider: PackageMetadataProvider {
    private static let apiHostPrefix = "api."

    private let authTokens: [AuthTokenType: String]
    private let httpClient: LegacyHTTPClient
    private let decoder: JSONDecoder

    init(authTokens: [AuthTokenType: String] = [:], httpClient: LegacyHTTPClient? = nil) {
        self.authTokens = authTokens
        self.httpClient = httpClient ?? Self.makeDefaultHTTPClient()
        self.decoder = JSONDecoder.makeWithDefaults()
    }

    func get(_ packageURL: URL) async throws -> PackageBasicMetadata {
        try await withCheckedThrowingContinuation { continuation in
            
            guard let baseURL = self.apiURL(packageURL.absoluteString) else {
                return continuation.resume(throwing: Errors.invalidGitURL(packageURL))
            }
            
            let metadataURL = baseURL
            let readmeURL = baseURL.appendingPathComponent("readme")
            let licenseURL = baseURL.appendingPathComponent("license")
            
            let sync = DispatchGroup()
            let results = ThreadSafeKeyValueStore<URL, Result<HTTPClientResponse, Error>>()
            
            // get the main data
            sync.enter()
            var metadataHeaders = HTTPClientHeaders()
            metadataHeaders.add(name: "Accept", value: "application/vnd.github.mercy-preview+json")
            let metadataOptions = self.makeRequestOptions(validResponseCodes: [200, 401, 403, 404])
            let hasAuthorization = metadataOptions.authorizationProvider?(metadataURL) != nil
            self.httpClient.get(metadataURL, headers: metadataHeaders, options: metadataOptions) { result in
                defer { sync.leave() }
                results[metadataURL] = result
                if case .success(let response) = result {
                    let apiLimit = response.headers.get("X-RateLimit-Limit").first.flatMap(Int.init) ?? -1
                    let apiRemaining = response.headers.get("X-RateLimit-Remaining").first.flatMap(Int.init) ?? -1
                    switch (response.statusCode, hasAuthorization, apiRemaining) {
                    case (_, _, 0):
                        results[metadataURL] = .failure(Errors.apiLimitsExceeded(metadataURL, apiLimit, apiRemaining))
                    case (401, true, _):
                        results[metadataURL] = .failure(Errors.invalidAuthToken(metadataURL))
                    case (401, false, _):
                        results[metadataURL] = .failure(Errors.permissionDenied(metadataURL))
                    case (403, _, _):
                        results[metadataURL] = .failure(Errors.permissionDenied(metadataURL))
                    case (404, _, _):
                        results[metadataURL] = .failure(Errors.notFound(metadataURL))
                    case (200, _, _):
                        // if successful, fan out multiple API calls
                        [readmeURL, licenseURL].forEach { url in
                            sync.enter()
                            var headers = HTTPClientHeaders()
                            headers.add(name: "Accept", value: "application/vnd.github.v3+json")
                            let options = self.makeRequestOptions(validResponseCodes: [200])
                            self.httpClient.get(url, headers: headers, options: options) { result in
                                defer { sync.leave() }
                                results[url] = result
                            }
                        }
                    default:
                        results[metadataURL] = .failure(Errors.invalidResponse(metadataURL, "Invalid status code: \(response.statusCode)"))
                    }
                }
            }
            
            // process results
            sync.notify(queue: self.httpClient.configuration.callbackQueue) {
                do {
                    // check for main request error state
                    switch results[metadataURL] {
                    case .none:
                        throw Errors.invalidResponse(metadataURL, "Response missing")
                    case .some(.failure(let error)):
                        throw error
                    case .some(.success(let metadataResponse)):
                        guard let metadata = try metadataResponse.decodeBody(GetRepositoryResponse.self, using: self.decoder) else {
                            throw Errors.invalidResponse(metadataURL, "Empty body")
                        }
                        
                        let readme = try results[readmeURL]?.success?.decodeBody(Readme.self, using: self.decoder)
                        let license = try results[licenseURL]?.success?.decodeBody(License.self, using: self.decoder)
                        
                        let model = PackageBasicMetadata(
                            summary: metadata.description,
                            keywords: metadata.topics,
                            readmeURL: readme?.downloadURL,
                            license: license.flatMap { .init(name: $0.license.spdxID, url: $0.downloadURL) }
                        )
                        
                        continuation.resume(returning: model)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    internal func apiURL(_ url: String) -> Foundation.URL? {
        if let gitURL = GitURL.from(url) {
            return URL(string: "https://\(Self.apiHostPrefix)\(gitURL.host)/repos/\(gitURL.owner)/\(gitURL.repository)")
        }
        return nil
    }

    private func makeRequestOptions(validResponseCodes: [Int]) -> LegacyHTTPClientRequest.Options {
        var options = LegacyHTTPClientRequest.Options()
        options.addUserAgent = true
        options.validResponseCodes = validResponseCodes
        options.authorizationProvider = { url in
            url.host.flatMap { host in
                let host = host.hasPrefix(Self.apiHostPrefix) ? String(host.dropFirst(Self.apiHostPrefix.count)) : host
                return self.authTokens[.github(host)].flatMap { token in "token \(token)" }
            }
        }
        return options
    }

    private static func makeDefaultHTTPClient() -> LegacyHTTPClient {
        let client = LegacyHTTPClient()
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

private extension GitHubPackageMetadataProvider {
    struct GetRepositoryResponse: Codable {
        let name: String
        let fullName: String
        let description: String?
        let topics: [String]?

        private enum CodingKeys: String, CodingKey {
            case name
            case fullName = "full_name"
            case description
            case topics
        }
    }
}

private extension GitHubPackageMetadataProvider {
    struct Readme: Codable {
        let url: Foundation.URL
        let htmlURL: Foundation.URL
        let downloadURL: Foundation.URL

        private enum CodingKeys: String, CodingKey {
            case url
            case htmlURL = "html_url"
            case downloadURL = "download_url"
        }
    }

    struct License: Codable {
        let url: Foundation.URL
        let htmlURL: Foundation.URL
        let downloadURL: Foundation.URL
        let license: License

        private enum CodingKeys: String, CodingKey {
            case url
            case htmlURL = "html_url"
            case downloadURL = "download_url"
            case license
        }

        fileprivate struct License: Codable {
            let name: String
            let spdxID: String

            private enum CodingKeys: String, CodingKey {
                case name
                case spdxID = "spdx_id"
            }
        }
    }
}
