//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import TSCBasic
import XCTest

// From TSCTestSupport
func systemQuietly(_ args: [String]) throws {
    // Discard the output, by default.
    try Process.checkNonZeroExit(arguments: args)
}

// From https://github.com/apple/swift-argument-parser/blob/main/Sources/ArgumentParserTestHelpers/TestHelpers.swift with modifications
extension XCTest {
    var debugURL: URL {
        let bundleURL = Bundle(for: type(of: self)).bundleURL
        return bundleURL.lastPathComponent.hasSuffix("xctest")
            ? bundleURL.deletingLastPathComponent()
            : bundleURL
    }

    func executeCommand(
        command: String,
        exitCode: ExitCode = .success,
        file: StaticString = #file, line: UInt = #line
    ) throws -> (stdout: String, stderr: String) {
        let splitCommand = command.split(separator: " ")
        let arguments = splitCommand.dropFirst().map(String.init)

        let commandName = String(splitCommand.first!)
        let commandURL = self.debugURL.appendingPathComponent(commandName)
        guard (try? commandURL.checkResourceIsReachable()) ?? false else {
            throw CommandExecutionError.executableNotFound(commandURL.standardizedFileURL.path)
        }

        let process = Process()
        process.executableURL = commandURL
        process.arguments = arguments

        let output = Pipe()
        process.standardOutput = output
        let error = Pipe()
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let outputActual = String(data: outputData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        let errorActual = String(data: errorData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(process.terminationStatus, exitCode.rawValue, file: file, line: line)

        return (outputActual, errorActual)
    }

    enum CommandExecutionError: Error {
        case executableNotFound(String)
    }
}
