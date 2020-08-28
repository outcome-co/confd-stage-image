# confd-stage
![Release](https://github.com/outcome-co/confd-stage-image/workflows/Release/badge.svg?branch=v0.2.3) ![version-badge](https://img.shields.io/badge/version-0.2.3-brightgreen)

A small utility image that contains `confd`, typically to be used as part of a multi-stage build.

## Usage

```Dockerfile
# Grab confd from the dedicated build container
FROM outcomeco/confd-stage as confd

# Build the main container
FROM python:3.8

COPY --from=confd /go/bin/confd /app/bin/confd
```

## Development

Remember to run `./pre-commit.sh` when you clone the repository.
