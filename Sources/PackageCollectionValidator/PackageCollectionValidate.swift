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
import enum PackageCollections.ValidationError
import struct PackageCollections.ValidationMessage
import enum PackageCollectionsModel.PackageCollectionModel
import TSCBasic
import Utilities

public struct PackageCollectionValidate: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Validate an input package collection."
    )

    @Argument(help: "The path to the JSON document containing the package collection to be validated")
    private var inputPath: String

    @Flag(name: .long, help: "Warnings will fail validation in addition to errors")
    private var warningsAsErrors: Bool = false

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool = false

    typealias Model = PackageCollectionModel.V1

    public init() {}

    public func run() throws {
        Process.verbose = self.verbose

        print("Using input file located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        let validator = Model.Validator()

        let jsonDecoder = JSONDecoder.makeWithDefaults()

        let collection: Model.Collection
        do {
            collection = try jsonDecoder.decode(Model.Collection.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))
        } catch {
            printError("Failed to parse package collection: \(error)")
            throw error
        }

        let validationMessages = validator.validate(collection: collection) ?? []

        if validationMessages.isEmpty {
            return print("The package collection is valid.", inColor: .green, verbose: self.verbose)
        }

        let errorMessages: [ValidationMessage]
        if self.warningsAsErrors {
            errorMessages = validationMessages
        } else {
            errorMessages = validationMessages.filter { $0.level == .error }

            // Print warnings
            validationMessages.filter { $0.level == .warning }.forEach { warning in
                print("[Warning] \(warning.property.map { "\($0): " } ?? "")\(warning.message)", inColor: .yellow, verbose: self.verbose)
            }
        }

        let errors: [PackageCollections.ValidationError] = errorMessages.map {
            let error: ValidationError
            if let property = $0.property {
                error = .property(name: property, message: $0.message)
            } else {
                error = .other(message: $0.message)
            }

            print("[Error] \(error)", inColor: .red, verbose: self.verbose)
            return error
        }

        guard errors.isEmpty else {
            throw MultipleErrors(errors)
        }
    }

    struct MultipleErrors: Error {
        let errors: [Error]

        init(_ errors: [Error]) {
            self.errors = errors
        }
    }
}
