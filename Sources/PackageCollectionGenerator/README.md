# Package Collection Generator

The generator downloads the sources of a given list of packages and extracts metadata from 
package manifest for specific or most recent versions to construct a collection that can be consumed
by SwiftPM.

```
> swift run package-collection-generate --help
OVERVIEW: Generate a package collection from the given list of packages.

USAGE: package-collection-generate <input-path> <output-path> [--working-directory-path <working-directory-path>] [--revision <revision>] [--verbose]

ARGUMENTS:
  <input-path>            The path to the JSON document containing the list of packages to be processed 
  <output-path>           The path to write the generated package collection to 

OPTIONS:
  --working-directory-path <working-directory-path>
                          The path to the working directory where package repositories may have been cloned previously. A package repository that already exists in the
                          directory will be updated rather than cloned again.

                          Be warned that the tool does not distinguish these directories by their corresponding git repository URL--different repositories with the
                          same name will end up in the same directory.

                          Temporary directories will be used instead if this argument is not specified. 
  --revision <revision>   The revision number of the generated package collection 
  --verbose               Show extra logging for debugging purposes 
  -h, --help              Show help information.
```

### System Requirements

The generator requires Swift toolchains and Git to run.

## Input Format

The input is a JSON document that contains metadata about the collection and lists the packages to be included.

Collection metadata:

* `title`: The name of the package collection.
* `overview`: An overview of the packages that are included. **Optional.**
* `keywords`: An array of keywords that the collection is associated with. **Optional.**
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
  "title": "Sample Package Collection",
  "overview": "This is a sample package collection listing made-up packages.",
  "keywords": ["sample package collection"],
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
