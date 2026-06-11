#!/usr/bin/env bash
# Lightweight log rotator for the rift LaunchAgent.
#   - Keeps /tmp/rift_$USER.{out,err}.log capped at ~20 MB live, 10 gzipped generations.
#   - Patches rift's installed plist to RUST_LOG=debug if it drifted back to defaults
#     (rift service install regenerates the plist), and notifies once.
#   - Designed to run from its own LaunchAgent (installed via `rift-log-rotate.sh install`).
#
# Note: `rift service restart` uses `launchctl kickstart -k`, which does NOT re-read
# the plist. After a plist patch, you must `bootout` + `bootstrap` for launchd to
# pick up the new EnvironmentVariables — that's what the `reload` subcommand does.
# Reloading kills and restarts rift, which resets window state, so it's never done
# automatically; the user runs it manually when convenient.
#
# Subcommands: install | uninstall | rotate (default) | reload

set -euo pipefail

RIFT_PLIST="$HOME/Library/LaunchAgents/git.acsandmann.rift.plist"
ROTATE_LABEL="com.grunewaldt.rift-log-rotate"
ROTATE_PLIST="$HOME/Library/LaunchAgents/${ROTATE_LABEL}.plist"
ROTATE_SCRIPT="$HOME/.bin/rift-log-rotate.sh"
STATE_DIR="$HOME/.cache/rift-log-rotate"
NOTIFIED_SENTINEL="$STATE_DIR/notified"
LOCK_DIR="/tmp/rift-log-rotate.lock"

ROTATE_INTERVAL=300
SIZE_THRESHOLD=$((20 * 1024 * 1024))
MAX_GENERATIONS=10

USER_NAME="${USER:-$(id -un)}"
LOG_OUT="/tmp/rift_${USER_NAME}.out.log"
LOG_ERR="/tmp/rift_${USER_NAME}.err.log"

notify() {
  osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true
}

write_rotate_plist() {
  mkdir -p "$(dirname "$ROTATE_PLIST")"
  cat >"$ROTATE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${ROTATE_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${ROTATE_SCRIPT}</string>
        <string>rotate</string>
    </array>
    <key>StartInterval</key>
    <integer>${ROTATE_INTERVAL}</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>
EOF
}

cmd_install() {
  if [[ ! -x "$ROTATE_SCRIPT" ]]; then
    echo "error: $ROTATE_SCRIPT not present or not executable. Run 'chezmoi apply' first." >&2
    exit 1
  fi
  mkdir -p "$STATE_DIR"
  write_rotate_plist
  launchctl bootout "gui/$(id -u)/${ROTATE_LABEL}" || true
  launchctl bootstrap "gui/$(id -u)" "$ROTATE_PLIST"
  echo "installed ${ROTATE_LABEL} (every ${ROTATE_INTERVAL}s)"
  "$ROTATE_SCRIPT" rotate
}

cmd_uninstall() {
  launchctl bootout "gui/$(id -u)/${ROTATE_LABEL}" 2>/dev/null || true
  rm -f "$ROTATE_PLIST"
  echo "uninstalled ${ROTATE_LABEL}"
}

# Force launchd to re-read the rift plist (bootout + bootstrap). Required after
# a RUST_LOG patch, because kickstart-style restarts reuse cached env vars.
cmd_reload() {
  local uid
  uid=$(id -u)
  local target="gui/${uid}/git.acsandmann.rift"
  if [[ ! -f "$RIFT_PLIST" ]]; then
    echo "error: $RIFT_PLIST not found — is rift's service installed?" >&2
    exit 1
  fi
  launchctl bootout "$target" 2>/dev/null || true
  # bootout is mostly synchronous on modern macOS but be defensive.
  local i=0
  while launchctl print "$target" >/dev/null 2>&1 && ((i < 30)); do
    sleep 0.1
    i=$((i + 1))
  done
  launchctl bootstrap "gui/${uid}" "$RIFT_PLIST"
  echo "reloaded rift (bootout + bootstrap)"
}

# 0 = already debug, 1 = patched, 2 = plist absent or RUST_LOG key missing
ensure_rift_debug_logging() {
  [[ -f "$RIFT_PLIST" ]] || return 2
  local current
  current=$(awk '/<key>RUST_LOG<\/key>/{getline; print; exit}' "$RIFT_PLIST")
  [[ -n "$current" ]] || return 2
  [[ "$current" == *debug* ]] && return 0
  sed -i.bak '/<key>RUST_LOG<\/key>/{n;s|<string>.*</string>|<string>debug</string>|;}' "$RIFT_PLIST"
  return 1
}

# Returns 0 if the file was rotated, 1 if there was nothing to do.
rotate_one() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local size
  size=$(stat -f %z "$f" 2>/dev/null || echo 0)
  [[ "$size" -ge "$SIZE_THRESHOLD" ]] || return 1

  # Crash recovery: leftover .1 from a previous run.
  if [[ -f "$f.1" ]]; then
    gzip -f "$f.1" 2>/dev/null || rm -f "$f.1"
  fi

  # Shift .N.gz -> .(N+1).gz, evict the oldest.
  rm -f "$f.${MAX_GENERATIONS}.gz"
  local i
  for ((i = MAX_GENERATIONS - 1; i >= 1; i--)); do
    [[ -f "$f.$i.gz" ]] && mv -f "$f.$i.gz" "$f.$((i + 1)).gz"
  done

  # === CRITICAL SECTION: APFS clonefile (metadata-only CoW) + immediate truncate.
  # Race window between snapshot and truncate is just two consecutive syscalls.
  cp -c "$f" "$f.1" 2>/dev/null || cp "$f" "$f.1"
  : >"$f"
  # === END CRITICAL SECTION ===

  gzip -f "$f.1"
}

cmd_rotate() {
  # mkdir is atomic; serves as a poor-man's mutex.
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
  fi
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

  mkdir -p "$STATE_DIR"

  local rc=0
  ensure_rift_debug_logging || rc=$?
  case "$rc" in
  0) rm -f "$NOTIFIED_SENTINEL" ;;
  1)
    if [[ ! -f "$NOTIFIED_SENTINEL" ]]; then
      notify "rift log rotate" "Patched plist to RUST_LOG=debug. Run: rift-log-rotate.sh reload"
      : >"$NOTIFIED_SENTINEL"
    fi
    ;;
  2) : ;;
  esac

  local rotated=()
  if rotate_one "$LOG_OUT"; then rotated+=("$(basename "$LOG_OUT")"); fi
  if rotate_one "$LOG_ERR"; then rotated+=("$(basename "$LOG_ERR")"); fi
  if ((${#rotated[@]} > 0)); then
    local joined
    joined=$(
      IFS=,
      echo "${rotated[*]}"
    )
    # Report the rotated filenames (e.g. "rift_user.err.log"), not bare
    # "out"/"err" — the latter reads like a failure in a notification.
    notify "rift log rotate" "Rotated log: ${joined}"
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") {install|uninstall|rotate|reload}

  install     install the LaunchAgent that runs 'rotate' every ${ROTATE_INTERVAL}s
  uninstall   stop and remove the LaunchAgent
  rotate      one rotation pass (patches rift plist if drifted, rotates logs)
  reload      bootout + bootstrap rift so launchd re-reads its plist (kills + restarts rift)
EOF
}

case "${1:-rotate}" in
install) cmd_install ;;
uninstall) cmd_uninstall ;;
rotate) cmd_rotate ;;
reload) cmd_reload ;;
-h | --help) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
