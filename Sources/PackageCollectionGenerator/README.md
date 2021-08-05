# Package Collection Generator

The generator downloads the sources of a given list of packages and extracts metadata from 
package manifest for specific or most recent versions to construct a collection that can be consumed
by SwiftPM.

```
> swift run package-collection-generate --help
OVERVIEW: Generate a package collection from the given list of packages.

USAGE: package-collection-generate <input-path> <output-path> [--working-directory-path <working-directory-path>] [--revision <revision>] [--auth-token <auth-token> ...] [--pretty-printed] [--verbose]

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
  --auth-token <auth-token>
                          Auth tokens each in the format of type:host:token for retrieving additional package metadata via source
                          hosting platform APIs. Currently only GitHub APIs are supported. An example token would be github:github.com:<TOKEN>.   
  --pretty-printed        Format output using friendly indentation and line-breaks.
  -v, --verbose           Show extra logging for debugging purposes.
  -h, --help              Show help information.
```

### System Requirements

The generator requires Swift toolchains and Git to run.

## Input Format

The input is a JSON document that contains metadata about the collection and lists the packages to be included.

Collection metadata:

* `name`: The name of the package collection, for display purposes only.
* `overview`: A description of the package collection. **Optional.**
* `keywords`: An array of keywords that the collection is associated with. **Optional.**
* `author`: The author of this package collection. **Optional.**
    * `name`: The author name.
* `packages`: An array of package objects.

Each item in the `packages` array is a package object with the following fields:

* `url`: The URL of the package. Currently only Git repository URLs are supported.
* `summary`: A description of the package. **Optional.**
* `keywords`: An array of keywords that the package is associated with. **Optional.**
* `versions`: An array of package versions to include. **Optional.** If not specified, the generate will select the most recent versions.
* `excludedVersions`: An array of package versions to exclude. **Optional.** If a version is listed in both `versions` and `excludedVersions`, it will be excluded from the package collection. 
* `excludedProducts`: An array of product names to exclude. **Optional.**
* `excludedTargets`: An array of target names to exclude. **Optional.**
* `readmeURL`: The URL of the package's README. **Optional.**

### Example

```json
{
  "name": "Sample Package Collection",
  "overview": "This is a sample package collection listing made-up packages.",
  "keywords": ["sample package collection"],
  "packages": [
    {
      "url": "https://www.example.com/repos/RepoOne.git",
      "summary": "Package One",
      "keywords": ["sample package"],
      "versions": ["0.2.0", "0.1.0"],
      "excludedProducts": ["Foo"],
      "excludedTargets": ["Bar"],
      "readmeURL": "https://www.example.com/repos/RepoOne/README"
    },
    {
      "url": "https://www.example.com/repos/RepoTwo.git"
    }
  ],
  "author": {
    "name": "Jane Doe"
  }
}
```

## Package Metadata from Other Providers

The generator can retrieve package metadata such as summary, README URL, license, etc. from GitHub so that it is not necessary to provide them in the [collection input file](#input-format). To use this feature:
1. Create a [personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) for each of the GitHub instances where packages in the collection are hosted.
2. Set the ` --auth-token` option when running the generator. Auth token is in the format of `<TYPE>:<HOST>:<TOKEN>`. The only supported `TYPE` is `github`, e.g., `github:github.com:<TOKEN>`. Multiple auth tokens can be used and they should be separated by a space.

Property values defined in the collection input file have higher precedence than those retrieved through GitHub APIs. 
