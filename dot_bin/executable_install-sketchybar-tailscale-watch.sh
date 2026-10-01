#!/usr/bin/env bash
# Installs the sketchybar-tailscale-watch LaunchAgent (macOS only), which
# feeds the SketchyBar Tailscale item (items/tailscale.lua) with change events.
# Writes the LaunchAgent plist and (re)loads it. Does nothing on machines
# without a Tailscale CLI; the SketchyBar item is skipped there as well.
set -euo pipefail

label="earth.gru.sketchybar-tailscale-watch"
plist_path="$HOME/Library/LaunchAgents/$label.plist"
log="$HOME/Library/Logs/sketchybar-tailscale-watch.log"

# Same candidates and order as items/tailscale.lua
cli=""
for candidate in \
  /Applications/Tailscale.app/Contents/MacOS/tailscale \
  /usr/local/bin/tailscale \
  /opt/homebrew/bin/tailscale; do
  if [[ -e "$candidate" ]]; then
    cli="$candidate"
    break
  fi
done
if [[ -z "$cli" ]]; then
  echo "No Tailscale CLI found; not installing $label"
  exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# PATH: launchd's default lacks Homebrew, where jq and sketchybar live.
# ThrottleInterval: restart delay while Tailscale is not running.
cat <<PLIST >"$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/.bin/sketchybar-tailscale-watch</string>
        <string>${cli}</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>15</integer>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>StandardOutPath</key>
    <string>${log}</string>
    <key>StandardErrorPath</key>
    <string>${log}</string>
</dict>
</plist>
PLIST

domain="gui/$(id -u)"
# bootout is asynchronous; bootstrapping while the old instance is still being
# torn down fails with "Input/output error". Wait until it is gone.
if launchctl print "$domain/$label" >/dev/null 2>&1; then
  launchctl bootout "$domain/$label"
  for _ in $(seq 1 50); do
    launchctl print "$domain/$label" >/dev/null 2>&1 || break
    sleep 0.2
  done
fi
launchctl bootstrap "$domain" "$plist_path"
echo "Installed and started $label (log: ~/Library/Logs/sketchybar-tailscale-watch.log)"
