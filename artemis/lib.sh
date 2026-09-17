#!/usr/bin/env bash
# Shared helpers for the Artemis reviewer-study harness (luau).
# Sourced by compile.sh, test.sh and benchmark.sh; not meant to be run directly.

ARTEMIS_REPO_KEY="luau"

# Absolute path of the checkout root (parent of this artemis/ directory).
artemis_checkout_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# sync_workspace: mirror the checkout into a persistent workspace so that
# attempts pay incremental rather than clean build cost.
#   1. WORKSPACE="${HARD_OSS_WORKSPACE_ROOT:-/var/tmp/hard-oss-workspaces}/luau"
#   2. rsync -rlpgoD --checksum --delete checkout -> workspace, excluding build/ and .git/
#   3. export WORKSPACE (and CHECKOUT) for the caller
sync_workspace() {
    CHECKOUT="$(artemis_checkout_root)"
    WORKSPACE="${HARD_OSS_WORKSPACE_ROOT:-/var/tmp/hard-oss-workspaces}/${ARTEMIS_REPO_KEY}"
    mkdir -p "$WORKSPACE"
    echo "[artemis] syncing $CHECKOUT -> $WORKSPACE" >&2
    rsync -rlpgoD --checksum --delete \
        --exclude '/build/' \
        --exclude '/.git/' \
        --exclude '/artemis_results.json' \
        "$CHECKOUT/" "$WORKSPACE/"
    export CHECKOUT WORKSPACE
}
