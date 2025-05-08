#!/bin/sh

# shellcheck source=SCRIPTDIR/../lib/functions.sh
. "$CONFIG_DIR/lib/functions.sh"

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  case "$VOLUME" in
  [6-9][0-9] | 100)
    ICON="󰕾"
    ;;
  [3-5][0-9])
    ICON="󰖀"
    ;;
  [1-9] | [1-2][0-9])
    ICON="󰕿"
    ;;
  0)
    ICON="󰖁"
    ;;
  esac

  if [ "$VOLUME" -eq 0 ]; then
    bar_label=""
  else
    bar_label=$(generate_unicode_bar "$VOLUME")
  fi

  sketchybar --set "$NAME" icon="$ICON" label="$bar_label"
fi
