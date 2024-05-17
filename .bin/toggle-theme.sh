#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin"

LOG_FILE="$HOME/toggle-theme.log"
ROTATED_LOG_FILE="$LOG_FILE.1.zst"

# Function to perform log rotation
if [ -f "$LOG_FILE" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    log_size=$(stat -f%z "$LOG_FILE") # macOS-specific
  else
    log_size=$(stat -c%s "$LOG_FILE") # Linux-specific
  fi
  if ((log_size > 1048576)); then
    # Rotate the log file
    zstd -f --rm "$LOG_FILE" -o "$ROTATED_LOG_FILE" 2>/dev/null
  fi
fi

# Function to log a message with a timestamp
log_message() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Send all output to logfile
exec > >(tee -a "$LOG_FILE") 2>&1

# Check DARKMODE environment variable set by dark-mode-notify service
if [ "$DARKMODE" = "1" ]; then
  fish_theme="tokyonight_storm"
else
  fish_theme="tokyonight_day"
fi

# Collect all neovim PIDs
neovim_pids=$(pgrep -d ' ' nvim || true)

log_message "Starting..."

log_message "DARKMODE=$DARKMODE"
log_message "fish_theme=$fish_theme"
log_message "neovim_pids=$neovim_pids"

log_message "Setting fish theme"
fish -c "yes | fish_config theme save $fish_theme"

for neovim_pid in $neovim_pids; do
  log_message "Sending SIGUSR1 to Neovim process with PID $neovim_pid"
  kill -SIGUSR1 "$neovim_pid"
done

log_message "Done"
