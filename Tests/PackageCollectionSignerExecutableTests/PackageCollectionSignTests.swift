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

import Basics
@testable import PackageCollectionSigner
import PackageCollectionsModel
import PackageCollectionsSigning
@testable import TestUtilities
import TSCBasic

private typealias Model = PackageCollectionModel.V1

final class PackageCollectionSignTests: XCTestCase {
    func test_help() throws {
        XCTAssert(try executeCommand(command: "package-collection-sign --help")
            .stdout.contains("USAGE: package-collection-sign <input-path> <output-path> <private-key-path> [<cert-chain-paths> ...] [--verbose]"))
    }

    func test_endToEnd() throws {
        try withTemporaryDirectory(prefix: "PackageCollectionToolTests", removeTreeOnDeinit: true) { tmpDir in
            let inputPath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "test.json")
            let outputPath = tmpDir.appending(component: "signed-test.json")
            // These are not actually used since we are using MockPackageCollectionSigner
            let privateKeyPath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "Test_ec_key.pem")
            let certPath = AbsolutePath(#file).parentDirectory.appending(components: "Inputs", "Test_ec.cer")

            let cmd = try PackageCollectionSign.parse([
                inputPath.pathString,
                outputPath.pathString,
                privateKeyPath.pathString,
                certPath.pathString,
            ])

            // We don't have real certs so we have to use a mock signer
            let signer = MockPackageCollectionSigner()
            try cmd._run(signer: signer)

            let jsonDecoder = JSONDecoder.makeWithDefaults()

            // Assert the generated package collection
            let bytes = try localFileSystem.readFileContents(outputPath).contents
            let signedCollection = try jsonDecoder.decode(Model.SignedCollection.self, from: Data(bytes))
            XCTAssertEqual("test signature", signedCollection.signature.signature)
        }
    }
}

private struct MockPackageCollectionSigner: PackageCollectionSigner {
    func sign(collection: Model.Collection,
              certChainPaths: [URL],
              certPrivateKeyPath: URL,
              certPolicyKey: CertificatePolicyKey,
              callback: @escaping (Result<Model.SignedCollection, Error>) -> Void) {
        let signature = Model.Signature(
            signature: "test signature",
            certificate: Model.Signature.Certificate(
                subject: Model.Signature.Certificate.Name(userID: "test user id", commonName: "test subject", organizationalUnit: "test unit", organization: "test org"),
                issuer: Model.Signature.Certificate.Name(userID: nil, commonName: "test issuer", organizationalUnit: "test unit", organization: "test org")
            )
        )
        callback(.success(Model.SignedCollection(collection: collection, signature: signature)))
    }
}
