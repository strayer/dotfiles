#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/outdated-packages"
MISE_CACHE_FILE="$CACHE_DIR/mise-outdated.json"
CACHE_TTL=7200 # 2 hours in seconds

# Handle prune parameter
if [[ "${1:-}" == "prune" ]]; then
  if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "$CACHE_DIR"
    echo "Cache directory $CACHE_DIR removed"
  else
    echo "Cache directory $CACHE_DIR does not exist"
  fi
  exit 0
fi

mkdir -p "$CACHE_DIR"

get_mise_outdated() {
  if [[ -f "$MISE_CACHE_FILE" ]]; then
    local cache_age=$(($(date +%s) - $(stat -f %m "$MISE_CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $cache_age -lt $CACHE_TTL ]]; then
      cat "$MISE_CACHE_FILE"
      return
    fi
  fi

  local mise_result
  if mise_result="$(mise outdated --json 2>/dev/null)"; then
    echo "$mise_result" | tee "$MISE_CACHE_FILE"
  else
    echo '{}'
  fi
}

BREW_OUTDATED="$(brew outdated --json 2>/dev/null || echo '[]')"
MISE_OUTDATED="$(get_mise_outdated)"

jq -n --argjson brew "$BREW_OUTDATED" --argjson mise "$MISE_OUTDATED" '{"brew": $brew, "mise": $mise}'
