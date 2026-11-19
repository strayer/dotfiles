#!/usr/bin/env bash
# Lightweight log rotator for the rift LaunchAgent.
#   - Keeps /tmp/rift_$USER.{out,err}.log capped at ~20 MB live, 10 gzipped generations.
#   - Patches rift's installed plist to RUST_LOG=debug if it drifted back to defaults
#     (rift service install regenerates the plist), and notifies once.
#   - Runs from its own LaunchAgent, com.grunewaldt.rift-log-rotate, every 5 minutes
#     (installed by `dot-services install rift-log-rotate`).
#
# Note: `rift service restart` uses `launchctl kickstart -k`, which does NOT re-read
# the plist. After a plist patch, you must `bootout` + `bootstrap` for launchd to
# pick up the new EnvironmentVariables — that's what the `reload` subcommand does.
# Reloading kills and restarts rift, which resets window state, so it's never done
# automatically; the user runs it manually when convenient.
#
# Never run this with sudo: LaunchAgents live in the per-user gui/<uid> domain.
# As root, `id -u` is 0 and launchctl targets gui/0, which does not exist
# ("Bootstrap failed: 125: Domain does not support specified action").
#
# Subcommands: rotate (default) | reload

set -euo pipefail

if [[ "$(id -u)" -eq 0 || -n "${SUDO_USER:-}" ]]; then
  echo "error: do not run $(basename "$0") as root/with sudo." >&2
  echo "       LaunchAgents are managed in your own gui/<uid> domain; rerun without sudo." >&2
  exit 1
fi

RIFT_PLIST="$HOME/Library/LaunchAgents/git.acsandmann.rift.plist"
STATE_DIR="$HOME/.cache/rift-log-rotate"
NOTIFIED_SENTINEL="$STATE_DIR/notified"
LOCK_DIR="/tmp/rift-log-rotate.lock"

SIZE_THRESHOLD=$((20 * 1024 * 1024))
MAX_GENERATIONS=10

USER_NAME="${USER:-$(id -un)}"
LOG_OUT="/tmp/rift_${USER_NAME}.out.log"
LOG_ERR="/tmp/rift_${USER_NAME}.err.log"

notify() {
  osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true
}

# bootout is mostly synchronous on modern macOS, but a bootstrap issued too
# early fails with "5: Input/output error" / "37: Operation already in
# progress". Poll until the service target is gone (max ~3s).
bootout_and_wait() {
  local target="$1"
  launchctl bootout "$target" 2>/dev/null || true
  local i=0
  while launchctl print "$target" >/dev/null 2>&1 && ((i < 30)); do
    sleep 0.1
    i=$((i + 1))
  done
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
  bootout_and_wait "$target"
  launchctl bootstrap "gui/${uid}" "$RIFT_PLIST"
  local effective
  effective=$(launchctl print "$target" 2>/dev/null | awk '/RUST_LOG =>/{print $3; exit}')
  echo "reloaded rift (bootout + bootstrap), effective RUST_LOG=${effective:-unset}"
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
Usage: $(basename "$0") {rotate|reload}

  rotate      one rotation pass (patches rift plist if drifted, rotates logs)
  reload      bootout + bootstrap rift so launchd re-reads its plist (kills + restarts rift)

The LaunchAgent that runs 'rotate' periodically is installed and removed with
'dot-services install|uninstall rift-log-rotate'.
EOF
}

case "${1:-rotate}" in
rotate) cmd_rotate ;;
reload) cmd_reload ;;
-h | --help) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
