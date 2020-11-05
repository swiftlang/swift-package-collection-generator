import Foundation
import TSCBasic

public enum ShellUtilities {
    public static let shell = ProcessInfo.processInfo.environment["PACKAGES_FEED_GENERATOR_SHELL"] ?? "bash"

    @discardableResult
    public static func run(_ arguments: String...) throws -> String {
        try Process.checkNonZeroExit(arguments: arguments)
    }
}
