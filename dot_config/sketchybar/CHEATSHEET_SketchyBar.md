# SketchyBar Cheatsheet

This document provides a comprehensive reference for configuring SketchyBar. For a complete, interactive guide, you can always consult the [SketchyBar DeepWiki](https://deepwiki.com/FelixKratz/SketchyBar).

## General Syntax

- **Set a property**: `sketchybar --set <item_name> <property>=<value>`
- **Set a bar property**: `sketchybar --bar <property>=<value>`
- **Add an item**: `sketchybar --add item <item_name> <position>`
- **Subscribe to an event**: `sketchybar --subscribe <item_name> <event_name>`
- **Batch commands**: `sketchybar --set item1... \ --set item2...`

---

## Bar Properties

Properties to configure the main bar. Use with `sketchybar --bar <property>=<value>`.

| Property          | Type         | Description                                                                  |
| ----------------- | ------------ | ---------------------------------------------------------------------------- |
| `position`        | `string`     | `top`, `bottom`, `left`, `right`.                                            |
| `height`          | `int`        | Height of the bar.                                                           |
| `margin`          | `float`      | Margin around the bar.                                                       |
| `y_offset`        | `int`        | Vertical offset.                                                             |
| `x_offset`        | `int`        | Horizontal offset.                                                           |
| `color`           | `color`      | Background color.                                                            |
| `border_width`    | `int`        | Width of the border.                                                         |
| `border_color`    | `color`      | Color of the border.                                                         |
| `blur_radius`     | `int`        | Background blur radius.                                                      |
| `display`         | `string`     | `main`, `active`, `all`, or display index `1`, `2`, ...                        |
| `padding_left`    | `int`        | Left padding for items.                                                      |
| `padding_right`   | `int`        | Right padding for items.                                                     |
| `notch_width`     | `int`        | Width of the notch area to avoid.                                            |
| `notch_offset`    | `float`      | Horizontal offset for the notch. (0.0 - 1.0)                                 |
| `topmost`         | `bool`       | `on`, `off`. Whether the bar is always on top.                               |
| `sticky`          | `bool`       | `on`, `off`. Whether the bar is visible on all spaces.                       |
| `font_smoothing`  | `bool`       | `on`, `off`.                                                                 |
| `hidden`          | `bool`       | `on`, `off`. Hides the bar.                                                  |

---

## Item Properties

Properties to configure individual items. Use with `sketchybar --set <item_name> <property>=<value>`.

### General

| Property          | Type         | Description                                                                  |
| ----------------- | ------------ | ---------------------------------------------------------------------------- |
| `drawing`         | `bool`       | `on`, `off`. Toggles visibility of the item.                                 |
| `position`        | `string`     | `left`, `right`, `center`.                                                   |
| `updates`         | `string`     | `on`, `off`, `when_shown`. When the script should be run.                    |
| `update_freq`     | `int`        | Update frequency in seconds for the script.                                  |
| `script`          | `string`     | Path to the script to execute.                                               |
| `click_script`    | `string`     | Script to run on click.                                                      |
| `label.font`      | `string`     | e.g., `"Helvetica:Bold:14.0"`                                                |
| `label.color`     | `color`      | Color of the label.                                                          |
| `label.padding_left` | `int`     |                                                                              |
| `label.padding_right`| `int`     |                                                                              |
| `icon.font`       | `string`     | e.g., `"Font Awesome 6 Free:Solid:12.0"`                                     |
| `icon.color`      | `color`      | Color of the icon.                                                           |
| `icon.padding_left`| `int`      |                                                                              |
| `icon.padding_right`| `int`      |                                                                              |
| `background.color`| `color`      | Background color for the item.                                               |
| `background.border_color`| `color`|                                                                              |
| `background.border_width`| `int` |                                                                              |
| `background.corner_radius`| `int`|                                                                              |
| `background.height`| `int`       |                                                                              |
| `background.padding_left`| `int` |                                                                              |
| `background.padding_right`| `int`|                                                                              |
| `shadow`          | `bool`       | `on`, `off`.                                                                 |
| `shadow.color`    | `color`      |                                                                              |
| `shadow.angle`    | `int`        | Angle in degrees.                                                            |
| `shadow.distance` | `int`        |                                                                              |
| `width`           | `int` or `string` | `dynamic` or a fixed integer value.                                      |

### Popup Menus

| Property          | Type         | Description                                                                  |
| ----------------- | ------------ | ---------------------------------------------------------------------------- |
| `popup.drawing`   | `bool`       | `on`, `off`. Toggles visibility of the popup.                                |
| `popup.background.color` | `color` |                                                                              |
| `popup.background.border_width` | `int` |                                                                              |
| `popup.background.border_color` | `color` |                                                                              |
| `popup.background.corner_radius` | `int` |                                                                              |
| `popup.horizontal`| `bool`       | `on`, `off`.                                                                 |
| `popup.y_offset`  | `int`        |                                                                              |
| `popup.blur_radius`| `int`       |                                                                              |

---

## Special Components

Added via `sketchybar --add <component> ...`.

- **`space`**: `sketchybar --add space <name> <position> <template_name>`. Creates a space indicator.
- **`bracket`**: `sketchybar --add bracket <name> <item1> <item2> ...`. Groups items with a shared background.
- **`alias`**: `sketchybar --add alias <bundle_id> <position>`. Mirrors a macOS menu bar item.
- **`slider`**: `sketchybar --add slider <name> <position>`. A draggable slider.
- **`graph`**: `sketchybar --add graph <name> <position>`. Displays data graphically.

---

## Events & Scripting

- **Subscribe**: `sketchybar --subscribe <item_name> <event_name>`
- **Trigger Custom Event**: `sketchybar --trigger <event_name> [optional_payload]`
- **Common Events**: `mouse.clicked`, `mouse.entered`, `mouse.exited`, `front_app_switched`, `space_change`, `system_woke`, `power_source_change`.
- **Scripting Environment Variables**: `$SENDER`, `$NAME`, `$INFO` (for JSON payloads).

---

## Animations

Prefix a `--set` or `--bar` command with `--animate` to animate property changes.
`sketchybar --animate <curve> <duration> --set <item_name> <property>=<value>`

- **Curves**: `linear`, `ease_in`, `ease_out`, `ease_in_out`, `spring`.
- **Duration**: In seconds.

---

## Querying

Get information about the bar state in JSON format.
- `sketchybar --query bar`
- `sketchybar --query item.<item_name>`
- `sketchybar --query all_items`
- `sketchybar --query events`
- `sketchybar --query displays`

---

For more details, refer to the [official documentation](https://felixkratz.github.io/SketchyBar/) or the [DeepWiki page](https://deepwiki.com/FelixKratz/SketchyBar).
