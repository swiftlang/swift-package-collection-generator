import Foundation

// Note: Not using SwiftPM's `PackageDescription` to avoid issues with
// different tools versions and we only need partial data.

/// Represents output of `swift package describe --type json`.
struct PackageDescription: Decodable {
    let name: String
    let targets: [Target]

    struct Target: Decodable {
        let name: String
        let c99name: String
    }
}
