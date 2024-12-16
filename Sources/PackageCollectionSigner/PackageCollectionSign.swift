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

import PackageCollectionsSigning

import ArgumentParser
import Dispatch
import Foundation

import Backtrace
import Basics
import PackageCollectionsModel
import PackageCollectionsSigning
import Utilities

@main
public struct PackageCollectionSign: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Sign a package collection."
    )

    @Argument(help: "The path to the package collection file to be signed")
    var inputPath: String

    @Argument(help: "The path to write the signed package collection to")
    var outputPath: String

    @Argument(help: "The path to certificate's private key (PEM encoded)")
    var privateKeyPath: String

    @Argument(help: "Paths to all certificates (DER encoded) in the chain. The certificate used for signing must be first and the root certificate last.")
    var certChainPaths: [String]

    @Flag(name: .shortAndLong, help: "Show extra logging for debugging purposes.")
    var verbose: Bool = false

    typealias Model = PackageCollectionModel.V1

    public init() {}

    public func run() async throws {
        try await self._run(signer: nil)
    }

    func _run(signer: PackageCollectionSigner?) async throws {
        Backtrace.install()

        guard !self.certChainPaths.isEmpty else {
            printError("Certificate chain cannot be empty")
            throw PackageCollectionSigningError.emptyCertChain
        }

        print("Signing package collection located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        let jsonDecoder = JSONDecoder.makeWithDefaults()
        let collection = try jsonDecoder.decode(Model.Collection.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))

        let privateKeyURL = URL(fileURLWithPath: self.privateKeyPath)
        let certChainURLs: [URL] = try self.certChainPaths.map { try ensureAbsolute(path: $0).asURL }

        try await withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // The last item in the array is the root certificate and we want to trust it, so here we
            // create a temp directory, copy the root certificate to it, and make it the trustedRootCertsDir.
            let rootCertPath = try AbsolutePath(validating: certChainURLs.last!.path) // !-safe since certChain cannot be empty at this point
            let rootCertFilename = rootCertPath.components.last!
            try localFileSystem.copy(from: rootCertPath, to: tmpDir.appending(component: rootCertFilename))

            // Sign the collection
            let signer = signer ?? PackageCollectionSigning(trustedRootCertsDir: tmpDir.asURL,
                                                            observabilityScope: ObservabilitySystem { _, diagnostic in print(diagnostic) }.topScope)
            let signedCollection = try await signer.sign(
                collection: collection,
                certChainPaths: certChainURLs,
                certPrivateKeyPath: privateKeyURL,
                certPolicyKey: .default
            )

            // Make sure the output directory exists
            let outputAbsolutePath = try ensureAbsolute(path: self.outputPath)
            let outputDirectory = outputAbsolutePath.parentDirectory
            try localFileSystem.createDirectory(outputDirectory, recursive: true)

            // Write the signed collection
            let jsonEncoder = JSONEncoder.makeWithDefaults(sortKeys: true, prettyPrint: false, escapeSlashes: false)
            let jsonData = try jsonEncoder.encode(signedCollection)
            try jsonData.write(to: URL(fileURLWithPath: outputAbsolutePath.pathString))
            print("Signed package collection saved to \(outputAbsolutePath)", inColor: .cyan, verbose: self.verbose)
        }
    }
}
