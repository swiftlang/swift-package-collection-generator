# Package Feed

Package feeds are short, curated lists of packages and associated metadata that can be imported
by SwiftPM to make package discovery easier. Educators and community influencers can publish
package feeds to go along with course materials or blog posts, removing the friction of using
packages for the first time and the cognitive overload of deciding which packages are useful for
a particular task. Enterprises may use feeds to narrow the decision space for their internal
engineering teams, focusing them on a trusted set of vetted packages.

## Create a Package Feed

Package feeds are JSON documents and contain a list of packages and additional metadata per package.

To begin, define the top-level metadata about the feed:

- `title`: The name of the package feed.
- `overview`: An overview of the packages that are included. *Optional*.
- `keywords`: Keywords that the feed is associated with. *Optional*.
- `formatVersion`: The version of the format to which the feed conforms. Currently, `1.0` is the
only format version.
- `generatedAt`: The ISO 8601-formatted datetime when the package feed was generated.
- `packages`: An array of package objects.

### Add Packages to the Feed

Each item in the `packages` array is a package object with the following fields:

- `url`: The URL of the package. Currently only Git repository URLs are supported.
- `summary`: A summary or description of what the package does etc. *Optional*.
- `readmeURL`: URL of the package's README. *Optional*.
- `versions`: An array of version objects representing the most recent and/or
relevant releases of the package.

### Add Versions to a Package

A version object has metadata extracted from `Package.swift` and other sources:

- `version`: The semantic version string.
- `packageName`: The name of the package.
- `targets`: An array of the package version's targets.
  - `name`: The target's name.
  - `moduleName`: The module name if this target can be imported as a module. *Optional*.
- `products`: An array of the package version's products. A product object's `type`
must have the same JSON serialization as SwiftPM's `PackageModel.ProductType`.

```json
{
    "name": "MyProduct",
    "type": {
        "library": ["automatic"]
    },
    "targets": ["MyTarget"]
}
```
- `toolsVersion`: The tools version specified in `Package.swift`.
- `verifiedPlatforms`: An array of the package version's **verified** platforms,
e.g., `macOS`, `Linux`, etc. *Optional*.

```json
{
    "name": "macOS"
}
```

- `verifiedSwiftVersions`: An array of the package version's **verified** Swift
versions. These must be semantic version strings. *Optional*.
- `license`: The package version's license. *Optional*.
  - `name`: License name, e.g., `Apache-2.0`, `MIT`, etc.
  - `url`: The URL of the license file.
