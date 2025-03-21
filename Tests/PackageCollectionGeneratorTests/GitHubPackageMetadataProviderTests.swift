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

import Foundation
import XCTest

import Basics
@testable import PackageCollectionGenerator
import enum TSCBasic.ProcessEnv

final class GitHubPackageMetadataProviderTests: XCTestCase {
    func test_apiURL() throws {
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")
        let provider = GitHubPackageMetadataProvider()

        do {
            let sshURLRetVal = provider.apiURL("git@github.com:octocat/Hello-World.git")
            XCTAssertEqual(apiURL, sshURLRetVal)
        }

        do {
            let httpsURLRetVal = provider.apiURL("https://github.com/octocat/Hello-World.git")
            XCTAssertEqual(apiURL, httpsURLRetVal)
        }

        do {
            let httpsURLRetVal = provider.apiURL("https://github.com/octocat/Hello-World")
            XCTAssertEqual(apiURL, httpsURLRetVal)
        }

        XCTAssertNil(provider.apiURL("bad/Hello-World.git"))
    }

    func testGood() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            guard request.headers.get("Authorization").first == "token \(authTokens.first!.value)" else {
                return completion(.success(.init(statusCode: 401)))
            }

            switch (request.method, request.url) {
            case (.get, apiURL):
                let data = try! self.readGitHubData(filename: "metadata.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            case (.get, apiURL.appendingPathComponent("readme")):
                let data = try! self.readGitHubData(filename: "readme.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            case (.get, apiURL.appendingPathComponent("license")):
                let data = try! self.readGitHubData(filename: "license.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            default:
                XCTFail("method and url should match")
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        let metadata = try await provider.get(repoURL)

        XCTAssertEqual("This your first repo!", metadata.summary)
        XCTAssertEqual(["octocat", "atom", "electron", "api"], metadata.keywords)
        XCTAssertEqual(URL(string: "https://raw.githubusercontent.com/octokit/octokit.rb/master/README.md"), metadata.readmeURL)
        XCTAssertEqual("MIT", metadata.license?.name)
        XCTAssertEqual(URL(string: "https://raw.githubusercontent.com/benbalter/gman/master/LICENSE?lab=true"), metadata.license?.url)
    }

    func testInvalidAuthToken() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            if request.headers.get("Authorization").first == "token \(authTokens.first!.value)" {
                completion(.success(.init(statusCode: 401)))
            } else {
                XCTFail("expected correct authorization header")
                completion(.success(.init(statusCode: 500)))
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        do {
            _ = try await provider.get(repoURL)
            XCTFail("should throw error")
        } catch {
            XCTAssertEqual(error as? GitHubPackageMetadataProvider.Errors, .invalidAuthToken(apiURL))
        }
    }

    func testRepoNotFound() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { _, _, completion in
            completion(.success(.init(statusCode: 404)))
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        do {
            _ = try await provider.get(repoURL)
            XCTFail("should throw error")
        } catch {
            XCTAssertEqual(error as? GitHubPackageMetadataProvider.Errors, .notFound(apiURL))
        }
    }

    func testOthersNotFound() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!
        let authTokens = [AuthTokenType.github("github.com"): "foo"]

        let handler: LegacyHTTPClient.Handler = { request, _, completion in
            guard request.headers.get("Authorization").first == "token \(authTokens.first!.value)" else {
                return completion(.success(.init(statusCode: 401)))
            }

            switch (request.method, request.url) {
            case (.get, apiURL):
                let data = try! self.readGitHubData(filename: "metadata.json")!
                completion(.success(.init(statusCode: 200,
                                          headers: .init([.init(name: "Content-Length", value: "\(data.count)")]),
                                          body: data)))
            default:
                completion(.success(.init(statusCode: 500)))
            }
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        let metadata = try await provider.get(repoURL)

        XCTAssertEqual("This your first repo!", metadata.summary)
        XCTAssertEqual(["octocat", "atom", "electron", "api"], metadata.keywords)
        XCTAssertNil(metadata.readmeURL)
        XCTAssertNil(metadata.license)
    }

    func testPermissionDenied() async throws {
        let repoURL = URL(string: "https://github.com/octocat/Hello-World.git")!
        let apiURL = URL(string: "https://api.github.com/repos/octocat/Hello-World")!

        let handler: LegacyHTTPClient.Handler = { _, _, completion in
            completion(.success(.init(statusCode: 401)))
        }

        let httpClient = LegacyHTTPClient(handler: handler)
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none

        let provider = GitHubPackageMetadataProvider(httpClient: httpClient)
        do {
            _ = try await provider.get(repoURL)
            XCTFail("should throw error")
        } catch {
            XCTAssertEqual(error as? GitHubPackageMetadataProvider.Errors, .permissionDenied(apiURL))
        }
    }

    func testInvalidURL() async throws {
        let repoURL = URL(string: "/")!
        let provider = GitHubPackageMetadataProvider()
        do {
            _ = try await provider.get(repoURL)
            XCTFail("should throw error")
        } catch {
            XCTAssertEqual(error as? GitHubPackageMetadataProvider.Errors, .invalidGitURL(repoURL))
        }
    }

    func testForRealz() async throws {
        #if ENABLE_GITHUB_NETWORK_TEST
        #else
        try XCTSkipIf(true)
        #endif

        let repoURL = URL(string: "https://github.com/apple/swift-numerics.git")!

        let httpClient = LegacyHTTPClient()
        httpClient.configuration.circuitBreakerStrategy = .none
        httpClient.configuration.retryStrategy = .none
        httpClient.configuration.requestHeaders = .init()
        httpClient.configuration.requestHeaders!.add(name: "Cache-Control", value: "no-cache")

        var authTokens: [AuthTokenType: String] = [:]
        if let token = ProcessEnv.vars["GITHUB_API_TOKEN"] {
            authTokens[.github("github.com")] = token
        }

        let provider = GitHubPackageMetadataProvider(authTokens: authTokens, httpClient: httpClient)
        for _ in 0 ... 60 {
            let metadata = try await provider.get(repoURL)
            XCTAssertNotNil(metadata)
            XCTAssert(metadata.keywords!.count > 0)
            XCTAssertNotNil(metadata.readmeURL)
            XCTAssertNotNil(metadata.license)
        }
    }

    private func readGitHubData(filename: String) throws -> Data? {
        let path = try AbsolutePath(validating: #file).parentDirectory.appending(components: "Inputs", "GitHub", filename)
        guard let contents = try? localFileSystem.readFileContents(path).contents else {
            return nil
        }
        return Data(contents)
    }
}
