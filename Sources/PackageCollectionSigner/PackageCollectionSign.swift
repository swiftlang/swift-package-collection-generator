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

import PackageCollectionsSigning

import ArgumentParser
import Dispatch
import Foundation

import Basics
import PackageCollectionsModel
import PackageCollectionsSigning

import TSCBasic
import Utilities

public struct PackageCollectionSign: ParsableCommand {
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

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    var verbose: Bool = false

    typealias Model = PackageCollectionModel.V1

    public init() {}

    public func run() throws {
        try self._run(signer: nil)
    }

    internal func _run(signer: PackageCollectionSigner?) throws {
        guard !self.certChainPaths.isEmpty else {
            printError("Certificate chain cannot be empty")
            throw PackageCollectionSigningError.emptyCertChain
        }

        Process.verbose = self.verbose

        print("Signing package collection located at \(self.inputPath)", inColor: .cyan, verbose: self.verbose)

        let jsonDecoder = JSONDecoder.makeWithDefaults()
        let collection = try jsonDecoder.decode(Model.Collection.self, from: Data(contentsOf: URL(fileURLWithPath: self.inputPath)))

        let privateKeyURL = URL(fileURLWithPath: self.privateKeyPath)
        let certChainURLs = self.certChainPaths.map(URL.init(fileURLWithPath:))

        try withTemporaryDirectory(removeTreeOnDeinit: true) { tmpDir in
            // The last item in the array is the root certificate and we want to trust it, so here we
            // create a temp directory, copy the root certificate to it, and make it the trustedRootCertsDir.
            let rootCertPath = AbsolutePath(certChainPaths.last!) // !-safe since certChain cannot be empty at this point
            let rootCertFilename = rootCertPath.components.last!
            try localFileSystem.copy(from: rootCertPath, to: tmpDir.appending(component: rootCertFilename))

            // Sign the collection
            let signer = signer ?? PackageCollectionSigning(trustedRootCertsDir: tmpDir.asURL, callbackQueue: DispatchQueue.global(), diagnosticsEngine: DiagnosticsEngine())
            let signedCollection = try tsc_await { callback in
                signer.sign(collection: collection, certChainPaths: certChainURLs, certPrivateKeyPath: privateKeyURL, certPolicyKey: .default, callback: callback)
            }

            // Make sure the output directory exists
            let outputAbsolutePath: AbsolutePath
            do {
                outputAbsolutePath = try AbsolutePath(validating: self.outputPath)
            } catch {
                outputAbsolutePath = AbsolutePath(self.outputPath, relativeTo: AbsolutePath(FileManager.default.currentDirectoryPath))
            }
            let outputDirectory = outputAbsolutePath.parentDirectory
            try localFileSystem.createDirectory(outputDirectory, recursive: true)

            // Write the signed collection
            let jsonEncoder = JSONEncoder.makeWithDefaults(prettified: false)
            let jsonData = try jsonEncoder.encode(signedCollection)
            try jsonData.write(to: URL(fileURLWithPath: outputAbsolutePath.pathString))
            print("Signed package collection saved to \(outputAbsolutePath)", inColor: .cyan, verbose: self.verbose)
        }
    }
}
