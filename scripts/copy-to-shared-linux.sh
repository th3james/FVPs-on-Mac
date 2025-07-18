#!/usr/bin/env bash
set -euo pipefail

# Ensure correct dir
cd "$(dirname "$0")/.."

# Remote target
REMOTE_HOST="shared-linux-workstation"
REMOTE_DIR="/data_sdb/th3james-src/FVP-Builder"

# Files to sync (relative to wherever you run this script)
FILES=(
  "extract-images.sh"
  "README-yocto-build.md"
  "build-yocto.Dockerfile"
  "corstone1000-full-fvp.yml"
)

# Ensure remote directory exists
echo "Ensuring ${REMOTE_DIR} exists on ${REMOTE_HOST}..."
ssh "${REMOTE_HOST}" "mkdir -p -- '${REMOTE_DIR}'"

# Build an rsync include-list
INCLUDE_ARGS=()
for f in "${FILES[@]}"; do
  INCLUDE_ARGS+=( --include="${f}" )
done

# Always exclude everything else
INCLUDE_ARGS+=( --exclude="*" )

# Run rsync in archive mode: update only changed files, preserve perms/times
echo "Syncing selected files to ${REMOTE_HOST}:${REMOTE_DIR} (idempotent)…"
rsync -av --prune-empty-dirs "${INCLUDE_ARGS[@]}" ./ "${REMOTE_HOST}:${REMOTE_DIR}/"

echo "Done. Only new or modified files were transferred."
