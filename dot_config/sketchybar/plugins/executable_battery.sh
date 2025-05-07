#!/usr/bin/env bash

# shellcheck source=SCRIPTDIR/../lib/functions.sh
source "$CONFIG_DIR/lib/functions.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100)
  ICON=""
  ;;
[6-8][0-9])
  ICON=""
  ;;
[3-5][0-9])
  ICON=""
  ;;
[1-2][0-9])
  ICON=""
  ;;
*) ICON="" ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON=""
fi

bar_label=$(generate_unicode_bar "$PERCENTAGE")

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="$bar_label"
