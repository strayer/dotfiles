#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin"

readonly LOG_SIZE_LIMIT=1048576  # 1MB
readonly LOG_FILE="$HOME/toggle-theme.log"
readonly ROTATED_LOG_FILE="$LOG_FILE.1.zst"
readonly SYSTEM_THEME_FILE="$HOME/.cache/system-theme.txt"
readonly WEZTERM_SYSTEM_THEME_FILE="$HOME/.config/wezterm/current-system-theme.lua"

# Function to perform log rotation
if [ -f "$LOG_FILE" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    log_size=$(stat -f%z "$LOG_FILE") # macOS-specific
  else
    log_size=$(stat -c%s "$LOG_FILE") # Linux-specific
  fi
  if ((log_size > LOG_SIZE_LIMIT)); then
    # Rotate the log file
    zstd -f --rm "$LOG_FILE" -o "$ROTATED_LOG_FILE" 2>/dev/null
  fi
fi

# Function to log a message with a timestamp
log_message() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to validate theme names for security
validate_theme_name() {
  local theme="$1"
  # Allow only alphanumeric, spaces, hyphens, and underscores
  if [[ ! "$theme" =~ ^[a-zA-Z0-9[:space:]_-]+$ ]]; then
    log_message "Error: Invalid theme name contains unsafe characters: $theme"
    exit 1
  fi
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
    # Do not auto-switch to light theme
    log_message "System environment indicates light theme. Exiting without changes."
    exit 0
  fi
  theme_source="environment variable"
fi

if [ "$theme" == "dark" ]; then
  fish_theme="tokyonight_storm"
  kitty_theme="Tokyo Night Storm"
  lsd_theme="colors-tokyonight.yaml"
  fish -c "set -Ue AICHAT_LIGHT_THEME"
  fish -c "set -Ux BAT_THEME 'tokyonight_storm'"
  fish -c "set -Ux DELTA_FEATURES '+tokyonight-storm'"
else
  fish_theme="Catppuccin Latte"
  kitty_theme="Catppuccin-Latte"
  lsd_theme="colors-cattpuccin-latte.yaml"
  fish -c "set -Ux AICHAT_LIGHT_THEME true"
  fish -c "set -Ux BAT_THEME 'Catppuccin Latte'"
  fish -c "set -Ux DELTA_FEATURES '+Catppuccin Latte'"
fi

# Collect all neovim PIDs
neovim_pids=$(pgrep -d ' ' nvim || true)

log_message "Selected theme=$theme from $theme_source"
log_message "fish_theme=$fish_theme"
log_message "kitty_theme=$kitty_theme"
log_message "lsd_theme=$lsd_theme"
log_message "neovim_pids=$neovim_pids"

log_message "Setting system and wezterm theme"
echo -n "$theme" >"$SYSTEM_THEME_FILE"
echo "return \"$theme\"" >"$WEZTERM_SYSTEM_THEME_FILE"

log_message "Setting fish theme"
validate_theme_name "$fish_theme"
fish -c "yes | fish_config theme save $(printf '%q' "$fish_theme")"

log_message "Setting kitty theme"
if command -v kitten &>/dev/null; then
  validate_theme_name "$kitty_theme"
  kitten themes --reload-in=all "$kitty_theme"
else
  log_message "kitty command not found, skipping theme change."
fi

log_message "Setting lsd theme"
lsd_config_dir="$HOME/.config/lsd"
lsd_colors_file="$lsd_config_dir/colors.yaml"
lsd_target_file="$lsd_config_dir/$lsd_theme"

if [ -f "$lsd_target_file" ]; then
  ln -sf "$lsd_target_file" "$lsd_colors_file"
  log_message "LSD theme symlink created: $lsd_colors_file -> $lsd_target_file"
else
  log_message "Warning: LSD theme file not found: $lsd_target_file"
fi

if [[ -n "${neovim_pids}" ]]; then
  for neovim_pid in ${neovim_pids}; do
    log_message "Sending SIGUSR1 to Neovim process with PID $neovim_pid"
    kill -SIGUSR1 "$neovim_pid"
  done
fi

log_message "Done"
