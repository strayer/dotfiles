#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

# shellcheck source=SCRIPTDIR/../lib/colors.sh
source "$CONFIG_DIR/lib/colors.sh"
# shellcheck source=SCRIPTDIR/../lib/icon_map.sh
source "$CONFIG_DIR/lib/icon_map.sh"

# retrieve FOCUSED_WORKSPACE in case it was not set by SketchyBar
# only the waerospace_workspace_change sets this, so this can happen quite often
if [[ -z "$FOCUSED_WORKSPACE" ]]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

WORKSPACE_WINDOWS=$(aerospace list-windows --workspace "$1" --json --format "%{monitor-appkit-nsscreen-screens-id}%{app-name}")

icons=""
IFS=$'\n'
for app_name in $(jq -r "map ( .\"app-name\" ) | .[]" <<<"$WORKSPACE_WINDOWS"); do
  __icon_map "$app_name"
  if [[ -n "$icon_result" ]]; then
    icons+="${icon_result} "
  fi
done

# Trim the last space if icons is not empty
if [[ -n "$icons" ]]; then
  icons="${icons% }"
fi

WORKSPACE_MONITOR=$(jq -r '(.[-1]."monitor-appkit-nsscreen-screens-id" // "1")' <<<"$WORKSPACE_WINDOWS")
if [[ -z "$icons" && "$1" != "$FOCUSED_WORKSPACE" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Array to hold sketchybar options
declare -a sketchybar_options=()
sketchybar_options+=(--set "$NAME")

# Common settings
sketchybar_options+=(display="$WORKSPACE_MONITOR")
sketchybar_options+=(drawing=on)
sketchybar_options+=(label="$icons")

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  # Focused workspace
  sketchybar_options+=(label.color="$BACKGROUND")
  sketchybar_options+=(icon.color="$BACKGROUND")
  sketchybar_options+=(background.color="$ACCENT_COLOR")
else
  # Not focused, and icons is NOT empty (due to the early exit)
  sketchybar_options+=(label.color="$ACCENT_COLOR")
  sketchybar_options+=(icon.color="$ACCENT_COLOR")
  sketchybar_options+=(background.color="$BAR_COLOR")
fi

# Call sketchybar with all options
sketchybar "${sketchybar_options[@]}"
