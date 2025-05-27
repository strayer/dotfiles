#!/usr/bin/env sh

# shellcheck source=SCRIPTDIR/../lib/colors.sh
source "$CONFIG_DIR/lib/colors.sh"

ping=$("$HOME/.bin/single-ping" 1.1.1.1)

if [ $? -ne 0 ]; then
  sketchybar --set "$NAME" label="rtt:???" label.color="$CRITICAL_COLOR"
  exit 0
fi
# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

sketchybar --set "$NAME" label="rtt:$ping" label.color="$ITEM_PRIMARY"
