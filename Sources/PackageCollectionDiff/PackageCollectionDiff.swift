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

import ArgumentParser
import Foundation

import Basics
import PackageCollectionsModel
import TSCBasic
import Utilities

public struct PackageCollectionDiff: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Compare two package collections to determine if they are the same or different."
    )

    @Argument(help: "The path to the JSON document containing package collection #1")
    private var collectionOnePath: String

    @Argument(help: "The path to the JSON document containing package collection #2")
    private var collectionTwoPath: String

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool = false

    typealias Model = PackageCollectionModel.V1

    public init() {}

    public func run() throws {
        Process.verbose = self.verbose

        print("Comparing collections located at \(self.collectionOnePath) and \(self.collectionTwoPath)", inColor: .cyan, verbose: self.verbose)

        let jsonDecoder = JSONDecoder.makeWithDefaults()

        let collectionOne = try self.parsePackageCollection(at: self.collectionOnePath, using: jsonDecoder)
        let collectionTwo = try self.parsePackageCollection(at: self.collectionTwoPath, using: jsonDecoder)

        if self.collectionsAreEqual(collectionOne, collectionTwo) {
            return print("The package collections are the same.", inColor: .green, verbose: true)
        } else {
            return print("The package collections are different.", inColor: .red, verbose: true)
        }
    }

    private func parsePackageCollection(at path: String, using jsonDecoder: JSONDecoder) throws -> Model.Collection {
        do {
            return try jsonDecoder.decode(Model.Collection.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        } catch {
            printError("Failed to parse package collection: \(error)")
            throw error
        }
    }

    private func collectionsAreEqual(_ lhs: Model.Collection, _ rhs: Model.Collection) -> Bool {
        guard lhs.name == rhs.name else { return false }
        guard lhs.overview == rhs.overview else { return false }
        guard lhs.keywords == rhs.keywords else { return false }
        guard lhs.packages == rhs.packages else { return false }
        guard lhs.formatVersion == rhs.formatVersion else { return false }
        guard lhs.revision == rhs.revision else { return false }
        // Don't compare generatedAt
        guard lhs.generatedBy == rhs.generatedBy else { return false }
        return true
    }
}
