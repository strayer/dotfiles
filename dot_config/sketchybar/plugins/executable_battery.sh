#!/usr/bin/env bash

# shellcheck source=SCRIPTDIR/../lib/functions.sh
source "$CONFIG_DIR/lib/functions.sh"
# shellcheck source=SCRIPTDIR/../lib/colors.sh
source "$CONFIG_DIR/lib/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

if [ "$PERCENTAGE" -gt 95 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

COLOR="$ITEM_PRIMARY"

if [ "$PERCENTAGE" -le 15 ]; then
  COLOR="$CRITICAL_COLOR"
elif [ "$PERCENTAGE" -le 45 ]; then
  COLOR="$WARNING_COLOR"
fi

case "${PERCENTAGE}" in
9[0-9] | 100) # 90-100%
  ICON=""
  ;;
[6-8][0-9]) # 60-89%
  ICON=""
  ;;
[3-5][0-9]) # 30-59%
  ICON=""
  ;;
[1-2][0-9]) # 10-29%
  ICON=""
  ;;
*) # 0-9%
  ICON=""
  ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON=""
  COLOR="$ITEM_PRIMARY"
fi

bar_label=$(generate_unicode_bar "$PERCENTAGE")

sketchybar --set "$NAME" \
  icon="$ICON" icon.color="$COLOR" \
  label="$bar_label" label.color="$COLOR" \
  drawing=on
