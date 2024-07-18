#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin"

LOG_FILE="$HOME/toggle-theme.log"
ROTATED_LOG_FILE="$LOG_FILE.1.zst"
SYSTEM_THEME_FILE="$HOME/.cache/system-theme.txt"
WEZTERM_SYSTEM_THEME_FILE="$HOME/.config/wezterm/current-system-theme.lua"

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

log_message "Starting..."

# Determine current theme and toggle if necessary
theme=""
theme_source=""

if [ -z "${DARKMODE+x}" ]; then
  if [ $# -gt 0 ]; then
    if [ "$1" == "dark" ]; then
      theme="dark"
      theme_source="parameter"
    elif [ "$1" == "light" ]; then
      theme="light"
      theme_source="parameter"
    else
      echo "Invalid argument. Use 'dark' or 'light'."
      exit 1
    fi
  else
    if [ -f "$SYSTEM_THEME_FILE" ]; then
      current_theme=$(cat "$SYSTEM_THEME_FILE")
      if [ "$current_theme" == "dark" ]; then
        theme="light"
      else
        theme="dark"
      fi
      theme_source="auto-toggle"
    else
      # Default to dark mode if no file exists
      theme="dark"
      theme_source="auto-toggle"
    fi
  fi
else
  if [ "$DARKMODE" = "1" ]; then
    theme="dark"
  else
    theme="light"
  fi
  theme_source="environment variable"
fi

if [ "$theme" == "dark" ]; then
  fish_theme="tokyonight_storm"
  # fish_theme="cyberdream"
  fish -c "set -Ue AICHAT_LIGHT_THEME"
else
  fish_theme="tokyonight_day"
  # fish_theme="cyberdream-light"
  fish -c "set -Ux AICHAT_LIGHT_THEME true"
fi

# Collect all neovim PIDs
neovim_pids=$(pgrep -d ' ' nvim || true)

log_message "Selected theme=$theme from $theme_source"
log_message "fish_theme=$fish_theme"
log_message "neovim_pids=$neovim_pids"

log_message "Setting system and wezterm theme"
echo -n "$theme" > "$SYSTEM_THEME_FILE"
echo "return \"$theme\"" > "$WEZTERM_SYSTEM_THEME_FILE"

log_message "Setting fish theme"
fish -c "yes | fish_config theme save $fish_theme"

for neovim_pid in $neovim_pids; do
  log_message "Sending SIGUSR1 to Neovim process with PID $neovim_pid"
  kill -SIGUSR1 "$neovim_pid"
done

log_message "Done"
