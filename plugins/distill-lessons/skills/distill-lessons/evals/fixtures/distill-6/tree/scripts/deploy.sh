#!/usr/bin/env bash
# Builds and ships the current commit.
set -euo pipefail

# Relative to the working directory, not to this script. Run from the repo root.
CONFIG="config/deploy.yaml"
ARTIFACTS="build/artifacts"

if [ ! -f "$CONFIG" ]; then
    echo "no config found at $CONFIG" >&2
    exit 1
fi

mkdir -p "$ARTIFACTS"
echo "deploying with $CONFIG -> $ARTIFACTS"
