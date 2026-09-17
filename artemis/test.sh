#!/usr/bin/env bash
# Artemis test step: run the interpreter conformance suite in the workspace.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Rebuild (incremental, no-op when unchanged) so binaries match the synced source.
bash "$(dirname "${BASH_SOURCE[0]}")/compile.sh"
sync_workspace
cd "$WORKSPACE"

if [ ! -x build/Luau.Conformance ]; then
    echo "[artemis] build/Luau.Conformance missing; run artemis/compile.sh first" >&2
    exit 1
fi

echo "[artemis] running Luau.Conformance --ts=Conformance" >&2
./build/Luau.Conformance --ts=Conformance 1>&2
echo "[artemis] test OK" >&2
