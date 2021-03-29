# Package Collection Signer

This tool is used for signing a package collection.

```
> swift run package-collection-sign --help
OVERVIEW: Sign a package collection.

USAGE: package-collection-sign <input-path> <output-path> <private-key-path> [<cert-chain-paths> ...] [--verbose]

ARGUMENTS:
  <input-path>            The path to the package collection file to be signed
  <output-path>           The path to write the signed package collection to
  <private-key-path>      The path to certificate's private key (PEM encoded)
  <cert-chain-paths>      Paths to all certificates (DER encoded) in the chain. The certificate used for signing must be first and the root
                          certificate last.

OPTIONS:
  --verbose               Show extra logging for debugging purposes
  -h, --help              Show help information.
```

### Sample Usage

```
> swift run package-collection-sign \
    my-collection.json \
    my-signed-collection.json \
    priivate-key.pem \
    certificate.cer intermediate_ca.cer root_ca.cer
```
