# Packages Feed Generator

The feed generator downloads the sources of a given list of packages and extracts metadata from 
package manifest for specific or most recent versions to construct a feed that can be consumed
by SwiftPM.

```
> swift run packages-feed-generate --help
OVERVIEW: Generate a package feed from the given list of packages.

USAGE: packages-feed-generate <input-path> <output-path> [--working-directory-path <working-directory-path>] [--revision <revision>] [--verbose]

ARGUMENTS:
  <input-path>            The path to the JSON document containing the list of packages to be processed 
  <output-path>           The path to write the generated package feed to 

OPTIONS:
  --working-directory-path <working-directory-path>
                          The path to the working directory where package repositories may have been cloned previously. A package repository that already exists in the
                          directory will be updated rather than cloned again.

                          Be warned that the tool does not distinguish these directories by their corresponding git repository URL--different repositories with the
                          same name will end up in the same directory.

                          Temporary directories will be used instead if this argument is not specified. 
  --revision <revision>   The revision number of the generated package feed 
  --verbose               Show extra logging for debugging purposes 
  -h, --help              Show help information.
```

### System Requirements

The feed generator requires Swift toolchains and Git.

## Input Format

The input is a JSON document that contains metadata about the feed and lists the packages to be included.

Feed metadata:

* `title`: The name of the package feed.
* `overview`: An overview of the packages that are included. **Optional.**
* `keywords`: An array of keywords that the feed is associated with. **Optional.**
* `packages`: An array of package objects.

Each item in the `packages` array is a package object with the following fields:

* `url`: The URL of the package. Currently only Git repository URLs are supported.
* `summary`: A summary or description of the package. **Optional.**
* `versions`: An array of package versions to include. **Optional.** If not specified, the generate will select the most recent versions.
* `excludedProducts`: An array of product names to exclude. **Optional.**
* `excludedTargets`: An array of target names to exclude. **Optional.**

### Example

```json
{
  "title": "Sample Package Feed",
  "overview": "This is a sample package feed listing made-up packages.",
  "keywords": ["sample package feed"],
  "packages": [
    {
      "url": "https://www.example.com/repos/RepoOne.git",
      "summary": "Package One",
      "versions": ["0.2.0", "0.1.0"],
      "excludedProducts": ["Foo"],
      "excludedTargets": ["Bar"]
    },
    {
      "url": "https://www.example.com/repos/RepoTwo.git"
    }
  ]
}
```
