#!/usr/bin/env bash
#
# Install SbarLua (Lua API for SketchyBar) and dependencies
#

set -euo pipefail

REPO="https://github.com/FelixKratz/SbarLua.git"

# Check dependencies
for cmd in git make cc luarocks; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not installed" >&2
    exit 1
  fi
done

# Create temp directory and clone
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Installing SbarLua..."
git clone --quiet "$REPO" "$TEMP_DIR/SbarLua"
cd "$TEMP_DIR/SbarLua"
make install
echo "SbarLua installed successfully!"

echo "Installing Lua modules with Luarocks..."
luarocks install http
luarocks install lua-cjson
echo "Lua modules installed successfully!"

