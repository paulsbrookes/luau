#!/usr/bin/env bash
# Artemis benchmark step: run the fixed 8-script interpreter benchmark subset
# in the workspace and publish artemis_results.json in the checkout root.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Rebuild (incremental, no-op when unchanged) so binaries match the synced source.
bash "$(dirname "${BASH_SOURCE[0]}")/compile.sh"
sync_workspace

# Remove stale results in both the checkout and the workspace.
rm -f "$CHECKOUT/artemis_results.json" "$WORKSPACE/artemis_results.json"

if [ ! -x "$WORKSPACE/build/luau" ]; then
    echo "[artemis] $WORKSPACE/build/luau missing; run artemis/compile.sh first" >&2
    exit 1
fi

echo "[artemis] running benchmark subset" >&2
python3 "$CHECKOUT/artemis/run_bench.py" \
    --luau "$WORKSPACE/build/luau" \
    --bench-dir "$WORKSPACE/bench" \
    --output "$CHECKOUT/artemis_results.json"

echo "[artemis] benchmark OK: $(cat "$CHECKOUT/artemis_results.json")" >&2
