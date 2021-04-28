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
import XCTest

@testable import Utilities

final class GitUtilitiesTests: XCTestCase {
    func testGitURL() throws {
        do {
            let gitURL = GitURL.from("https://github.com/octocat/Hello-World")
            XCTAssertEqual("github.com", gitURL?.host)
            XCTAssertEqual("octocat", gitURL?.owner)
            XCTAssertEqual("Hello-World", gitURL?.repository)
        }

        do {
            let gitURL = GitURL.from("https://github.com/octocat/Hello-World.git")
            XCTAssertEqual("github.com", gitURL?.host)
            XCTAssertEqual("octocat", gitURL?.owner)
            XCTAssertEqual("Hello-World", gitURL?.repository)
        }

        do {
            let gitURL = GitURL.from("git@github.com:octocat/Hello-World.git")
            XCTAssertEqual("github.com", gitURL?.host)
            XCTAssertEqual("octocat", gitURL?.owner)
            XCTAssertEqual("Hello-World", gitURL?.repository)
        }

        XCTAssertNil(GitURL.from("bad/Hello-World.git"))
    }
}
