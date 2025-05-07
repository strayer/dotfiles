#!/usr/bin/env bash

# Function to generate a Unicode progress bar
# Arguments:
#   $1: current percentage (0-100)
# Returns:
#   A string like "[████░░░░░░] 40%"
generate_unicode_bar() {
  local percentage=$1
  local display_width=10
  local filled_char="█"
  local empty_char="░"
  local bar_content=""
  local num_filled_blocks

  # Validate percentage input
  if ! [[ "$percentage" =~ ^[0-9]+$ ]] || [ "$percentage" -lt 0 ] || [ "$percentage" -gt 100 ]; then
    # Output to stderr and return an error indicator for the bar
    echo "Error: Percentage for bar must be an integer between 0 and 100. Received: $percentage" >&2
    echo "[ERR %]"
    return 1
  fi

  # Calculate number of filled blocks
  num_filled_blocks=$(((percentage * display_width) / 100))

  for i in $(seq 1 "$display_width"); do
    if [ "$i" -le "$num_filled_blocks" ]; then
      bar_content="${bar_content}${filled_char}"
    else
      bar_content="${bar_content}${empty_char}"
    fi
  done

  echo "[${bar_content}] ${percentage}%"
}
