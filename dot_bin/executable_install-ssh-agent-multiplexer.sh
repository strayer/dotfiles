#!/usr/bin/env bash
#
# Install ssh-agent-multiplexer (https://github.com/everpeace/ssh-agent-multiplexer)
# as a LaunchAgent. It merges the Secretive agent (Secure Enclave git signing
# key) and the default launchd ssh-agent (daily Smallstep certificate) behind
# a single socket, so tools that forward one SSH agent — e.g. Docker
# Sandboxes — see both keys. Config lives in
# ~/.config/ssh-agent-multiplexer/config.toml (managed by chezmoi).
#
# Pinned release, verified against the sha256 from the project's
# checksums.txt. Bump both together when updating.
#
# Usage: install-ssh-agent-multiplexer.sh [--uninstall]

set -euo pipefail

version="0.6.0"
sha256="5ac8d79bdee436a0e6a8c8dbfa53cbfc3c061ac4b48d6de890e7780b53a64cc2" # darwin_arm64
tarball="ssh-agent-multiplexer_${version}_darwin_arm64.tar.gz"
url="https://github.com/everpeace/ssh-agent-multiplexer/releases/download/v${version}/${tarball}"

bin_path="$HOME/.local/bin/ssh-agent-multiplexer"
plist_path="$HOME/Library/LaunchAgents/local.ssh-agent-multiplexer.plist"

if [ "${1:-}" = "--uninstall" ]; then
  launchctl unload -w "$plist_path" 2>/dev/null || true
  rm -f "$plist_path" "$bin_path" "$HOME/.ssh/ssh-agent-multiplexer.sock"
  echo "ssh-agent-multiplexer uninstalled"
  exit 0
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "Error: pinned checksum is for darwin_arm64 only" >&2
  exit 1
fi

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

echo "Downloading ssh-agent-multiplexer v${version}..."
curl -fsSL -o "$temp_dir/$tarball" "$url"
echo "${sha256}  $temp_dir/$tarball" | shasum -a 256 -c - >/dev/null

tar -xzf "$temp_dir/$tarball" -C "$temp_dir" ssh-agent-multiplexer
mkdir -p "$(dirname "$bin_path")"
install -m 755 "$temp_dir/ssh-agent-multiplexer" "$bin_path"
echo "Installed $bin_path"

# The upstream launchd agent socket path (/var/run/com.apple.launchd.*/Listeners)
# changes every boot, so the config references ${SSH_AUTH_SOCK} and the
# LaunchAgent resolves it from launchd's user environment at start.
cat <<EOF > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.ssh-agent-multiplexer</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
       <string>/bin/sh</string>
       <string>-c</string>
       <string>export SSH_AUTH_SOCK="\$(launchctl getenv SSH_AUTH_SOCK)"; exec "\$HOME/.local/bin/ssh-agent-multiplexer" run</string>
    </array>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/ssh-agent-multiplexer.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/ssh-agent-multiplexer.log</string>
</dict>
</plist>
EOF

launchctl unload "$plist_path" 2>/dev/null || true
launchctl load -w "$plist_path"
echo "LaunchAgent loaded; socket: ~/.ssh/ssh-agent-multiplexer.sock"
