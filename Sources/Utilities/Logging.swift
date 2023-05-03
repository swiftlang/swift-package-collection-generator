//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Package Collection Generator open source project
//
// Copyright (c) 2020-2023 Apple Inc. and the Swift Package Collection Generator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Package Collection Generator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import TSCBasic

public func print(_ string: String, inColor color: TerminalController.Color = .noColor, bold: Bool = false, verbose: Bool) {
    guard verbose else { return }
    InteractiveWriter.stdout.write(string, inColor: color, bold: bold)
}

public func printError(_ string: String) {
    InteractiveWriter.stderr.write(string, inColor: .red, bold: true)
}

/// This class is used to write on the underlying stream.
///
/// If underlying stream is a not tty, the string will be written in without any formatting.
private final class InteractiveWriter {
    /// The standard output writer.
    static let stdout = InteractiveWriter(stream: stdoutStream)

    /// The standard error writer.
    static let stderr = InteractiveWriter(stream: stderrStream)

    /// The terminal controller, if present.
    let term: TerminalController?

    /// The output byte stream reference.
    let stream: OutputByteStream

    /// Create an instance with the given stream.
    init(stream: OutputByteStream) {
        self.term = TerminalController(stream: stream)
        self.stream = stream
    }

    /// Write the string to the contained terminal or stream.
    func write(_ string: String, inColor color: TerminalController.Color = .noColor, bold: Bool = false) {
        if let term = term {
            term.write(string, inColor: color, bold: bold)
            term.endLine()
        } else {
            self.stream.send(string)
            self.stream.flush()
        }
    }
}
