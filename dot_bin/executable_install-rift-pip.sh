#!/usr/bin/env bash
#
# Install rift-pip (https://github.com/acsandmann/rift-pip), a Rift plugin that
# mirrors a window into a floating picture-in-picture window, with the local
# `--window <id>` patch from ~/.bin/src/rift-pip-window-option.patch applied.
# Installs into ~/.cargo/bin/rift-pip. Re-run to update.
#

set -euo pipefail

REPO="https://github.com/acsandmann/rift-pip"
REV="06e15a62428dd142750185af3060df897855fc0a" # upstream commit the patch was written against
PATCH="$HOME/.bin/src/rift-pip-window-option.patch"

for cmd in git cargo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not installed" >&2
    exit 1
  fi
done
if [ ! -f "$PATCH" ]; then
  echo "Error: patch not found at $PATCH (run chezmoi apply first)" >&2
  exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Cloning rift-pip at ${REV:0:7}..."
git clone --quiet "$REPO" "$TEMP_DIR/rift-pip"
cd "$TEMP_DIR/rift-pip"
git checkout --quiet "$REV"

echo "Applying --window patch..."
git apply --verbose "$PATCH"

echo "Building and installing rift-pip (this takes a minute)..."
cargo install --quiet --locked --path . --root "$HOME/.cargo"

echo
echo "Installed: $(command -v rift-pip || echo "$HOME/.cargo/bin/rift-pip")"
echo "rift-pip needs Screen Recording permission for the app that launches it."
echo "When Rift starts it via ~/.bin/rift-pip-auto, grant it to rift (or your terminal"
echo "when run by hand) under System Settings > Privacy & Security > Screen & System Audio Recording."
echo "A PiP that fails to start (e.g. before that permission is granted) is not retried"
echo "until the call's workspace has been visible again; see ~/.cache/rift-pip/rift-pip.log."
