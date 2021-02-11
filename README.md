# Swift Package Collection Generator

A **package collection** ([SE-0291](https://github.com/apple/swift-evolution/blob/main/proposals/0291-package-collections.md)) 
is a curated list of packages and associated metadata which makes it easier to discover an existing package for a particular use 
case. SwiftPM will allow users to subscribe to package collections and make their contents accessible to any clients of libSwiftPM.  

This repository provides a set of Swift packages and tooling for the generation and consumption of package collections.

## Package Collection Format

Package collections can be created and published by anyone. To make sure SwiftPM can consume 
them, all package collections must adhere to the same format. See the [v1 format](PackageCollectionFormats/v1.md) 
for details.

## Generating a Package Collection

[`package-collection-generate`](Sources/PackageCollectionGenerator/README.md) is a Swift
command-line tool that helps generate package collections.

## Validating a Package Collection

[`package-collection-validate`](Sources/PackageCollectionValidator/README.md) is a Swift
command-line tool that validates package collections against the defined format.

## Comparing Package Collections

[`package-collection-diff`](Sources/PackageCollectionDiff/README.md) is a Swift
command-line tool that compares two package collections to determine if they are different from each other. 
