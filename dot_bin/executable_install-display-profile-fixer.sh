#!/usr/bin/env bash
# Installs the display-profile-fixer LaunchAgent (macOS only).
# Compiles ~/.bin/display-profile-fixer.app from the Swift source if missing or
# outdated, writes the LaunchAgent plist, and (re)loads it.
# Re-run after `chezmoi apply` pulled a newer display-profile-fixer.swift.
#
# What it does: replaces the malformed ICC profiles that Dell Display and
# Peripheral Manager (DDPM) assigns to Dell monitors, which tint Chromium,
# Firefox and Electron apps and turn screenshots pink. A no-op on machines
# without DDPM.
set -euo pipefail

label="earth.gru.display-profile-fixer"
source="$HOME/.bin/display-profile-fixer.swift"
bundle="$HOME/.bin/display-profile-fixer.app"
binary="$bundle/Contents/MacOS/display-profile-fixer"
plist_path="$HOME/Library/LaunchAgents/$label.plist"

if [[ ! -x "$binary" || "$source" -nt "$binary" ]]; then
  "$HOME/.bin/compile-display-profile-fixer"
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

cat <<PLIST > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${binary}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/display-profile-fixer.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/display-profile-fixer.log</string>
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
echo "Installed and started $label (log: ~/Library/Logs/display-profile-fixer.log)"
