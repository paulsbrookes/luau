#!/usr/bin/env bash
# Artemis compile step: configure (Ninja, Release, -O2) and build the
# conformance test binary and the luau CLI inside the persistent workspace.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

sync_workspace
cd "$WORKSPACE"

echo "[artemis] configuring build/ in $WORKSPACE" >&2
cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
    -DLUAU_BUILD_CLI=ON \
    -DLUAU_BUILD_TESTS=ON \
    1>&2

echo "[artemis] building Luau.Conformance Luau.Repl.CLI (-j8)" >&2
cmake --build build --target Luau.Conformance Luau.Repl.CLI -j8 1>&2

test -x build/luau
test -x build/Luau.Conformance
echo "[artemis] compile OK" >&2
