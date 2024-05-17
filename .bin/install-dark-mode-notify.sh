#!/usr/bin/env bash
set -euo pipefail

plist_path="$HOME/Library/LaunchAgents/earth.gru.dark-mode-notify.plist"

cat <<EOF > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>earth.gru.dark-mode-notify</string>
    <key>KeepAlive</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
       <string>${HOME}/.bin/dark-mode-notify</string>
       <string>bash</string>
       <string>${HOME}/.bin/toggle-theme.sh</string>
    </array>
</dict>
</plist>
EOF

launchctl load -w "$plist_path"
