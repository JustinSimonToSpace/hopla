#!/bin/sh
# Builds a universal Hopla.app and zips it for a GitHub release, with its SHA-256.
set -eu
cd "$(dirname "$0")/.."
VERSION="$(cat VERSION)"
./scripts/test.sh
./scripts/make-app.sh --universal
ZIP="dist/Hopla-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent dist/Hopla.app "$ZIP"
shasum -a 256 "$ZIP" | tee "$ZIP.sha256"
echo "→ $ZIP"
