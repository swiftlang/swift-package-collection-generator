# Package Collection Validator

The validator checks a given package collection JSON document to ensure it is valid and can be consumed by SwiftPM.

```
> swift run package-collection-validate --help
OVERVIEW: Validate an input package collection.

USAGE: package-collection-validate <input-path> [--warnings-as-errors] [--verbose]

ARGUMENTS:
  <input-path>            The path to the JSON document containing the package collection to be validated

OPTIONS:
  --warnings-as-errors    Warnings will fail validation in addition to errors
  --verbose               Show extra logging for debugging purposes
  -h, --help              Show help information.
```
