#!/bin/sh
# Runs the unit tests. With Xcode installed, `swift test` is enough; with only the Command Line Tools,
# the Swift Testing framework lives outside the default search paths, so we point the build at it.
set -eu
cd "$(dirname "$0")/.."
DEV="$(xcode-select -p)"
case "$DEV" in
  *CommandLineTools*)
    F="$DEV/Library/Developer/Frameworks"
    L="$DEV/Library/Developer/usr/lib"
    exec swift test -Xswiftc -F -Xswiftc "$F" -Xlinker -F -Xlinker "$F" \
      -Xlinker -rpath -Xlinker "$F" -Xlinker -rpath -Xlinker "$L" --no-parallel "$@"
    ;;
  *)
    exec swift test --no-parallel "$@"
    ;;
esac
