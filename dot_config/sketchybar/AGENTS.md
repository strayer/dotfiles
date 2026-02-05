# AI Agent Guide for SketchyBar

This document provides guidance for AI coding agents (Claude Code, Gemini CLI, Cursor, etc.) when working with this SketchyBar configuration.

## Quick Reference

- **Documentation**: [SketchyBar DeepWiki](https://deepwiki.com/FelixKratz/SketchyBar), [SbarLua DeepWiki](https://deepwiki.com/FelixKratz/SbarLua)
- **Cheatsheets**: `CHEATSHEET_SketchyBar.md`, `CHEATSHEET_SBarLua.md`
- **Configuration Language**: Lua (SbarLua)
- **Entry Point**: `sketchybarrc` → `init.lua`

## SketchyBar Query Interface

The query interface is essential for debugging, inspecting state, and understanding the current bar configuration. All queries return JSON.

### Available Query Commands

```bash
# Query the main bar configuration
sketchybar --query bar

# Query a specific item by name
sketchybar --query <item_name>

# Query current default settings
sketchybar --query defaults

# Query registered events
sketchybar --query events

# Query display configuration
sketchybar --query displays

# Query native macOS menu bar items (for alias creation)
sketchybar --query default_menu_items
```

### Query Output Examples

**Bar query** (`sketchybar --query bar`):

```json
{
  "position": "top",
  "topmost": "off",
  "sticky": "on",
  "hidden": "off",
  "blur_radius": 0,
  "margin": 0,
  "color": "0x0",
  "height": 35,
  "corner_radius": 0,
  "padding_left": 5,
  "padding_right": 5,
  "y_offset": 3,
  "items": [
    "left.padding",
    "left.chevron",
    "left.space.1",
    "right.clock",
    "right.volume",
    "left_pill",
    "right_pill"
  ]
}
```

**Item query** (`sketchybar --query right.clock`):

```json
{
  "name": "right.clock",
  "type": "item",
  "geometry": {
    "drawing": "on",
    "position": "right",
    "background": {
      "drawing": "on",
      "color": "0x0",
      "height": 25,
      "corner_radius": 5
    }
  },
  "icon": {
    "value": "",
    "color": "0xffbac2de",
    "font": "PragmataPro:Bold:14.00",
    "padding_left": 7,
    "padding_right": 4
  },
  "label": {
    "value": "09.01. 16:12",
    "color": "0xffbac2de",
    "font": "PragmataPro:Bold:14.00"
  },
  "scripting": {
    "update_freq": 10,
    "updates": "when_shown"
  },
  "bounding_rects": {
    "display-1": {
      "origin": [1665.0, 3.0],
      "size": [121.0, 35.0]
    }
  }
}
```

**Events query** (`sketchybar --query events`):

```json
{
  "front_app_switched": { "bit": 1 },
  "space_change": { "bit": 2 },
  "display_change": { "bit": 4 },
  "system_woke": { "bit": 8 },
  "mouse.clicked": { "bit": 64 },
  "volume_change": { "bit": 4096 },
  "power_source_change": { "bit": 16384 },
  "theme_change": {
    "bit": 262144,
    "notification": "AppleInterfaceThemeChangedNotification"
  },
  "routine": { "bit": 524288 },
  "theme_colors_updated": { "bit": 1048576 },
  "aerospace_workspace_change": {
    "bit": 2097152,
    "notification": "aerospace_workspace_change_event"
  }
}
```

**Displays query** (`sketchybar --query displays`):

```json
[
  {
    "arrangement-id": 1,
    "DirectDisplayID": 1,
    "UUID": "37D8832A-2D66-02CA-B9F7-8F30A301B230",
    "frame": { "x": 0.0, "y": 0.0, "w": 1800.0, "h": 1169.0 }
  }
]
```

**Bracket query** (`sketchybar --query left_pill`):

```json
{
  "name": "left_pill",
  "type": "bracket",
  "geometry": {
    "background": {
      "color": "0x4c000000",
      "height": 31,
      "corner_radius": 9999
    }
  },
  "bracket": [
    "left.padding",
    "left.chevron",
    "left.space.1",
    "left.space.2",
    "left.theme_handler"
  ]
}
```

### Useful Query Patterns for Debugging

```bash
# List all item names
sketchybar --query bar | jq '.items'

# Check if an item is visible
sketchybar --query right.battery | jq '.geometry.drawing'

# Get current bar height
sketchybar --query bar | jq '.height'

# Inspect bracket members
sketchybar --query left_pill | jq '.bracket'

# Check display configuration for multi-monitor setups
sketchybar --query displays | jq '.[]'

# See all registered events
sketchybar --query events | jq 'keys'

# Get item position and size
sketchybar --query right.clock | jq '.bounding_rects'
```

## This Configuration's Architecture

### Directory Structure

```
sketchybar/
├── sketchybarrc  # Entry point, loads SbarLua module
├── init.lua                 # Loads bar.lua, default.lua, items/
├── bar.lua                  # Bar appearance (position, height, colors)
├── default.lua              # Default item styling
├── lib/                     # Shared modules
│   └── 3rdparty/            # Upstream dependencies (icon_map.lua)
└── items/                   # Individual bar items
```

### Item Naming Convention

Items follow a positional prefix pattern for bracket grouping:

- `left.*` - Items on the left side (grouped by `left_pill` bracket)
- `right.*` - Items on the right side (grouped by `right_pill` bracket)

This enables regex-based bracket matching: `"/left\\..*/"` and `"/right\\..*/"`

### Key Patterns

**Creating an item:**

```lua
local my_item = sbar.add("item", "right.my_item", {
  position = "right",
  icon = { string = "󰍉" },
  label = { string = "Hello" },
  update_freq = 60,  -- seconds
})
```

**Subscribing to events:**

```lua
my_item:subscribe("routine", update_function)
my_item:subscribe("system_woke", update_function)
my_item:subscribe("theme_colors_updated", update_function)
```

**Executing shell commands:**

```lua
sbar.exec("some-command", function(result, exit_code)
  if exit_code == 0 then
    my_item:set({ label = { string = result } })
  end
end)
```

**Using the color system:**

```lua
local colors = require("lib.colors")

-- Get base colors for normal state
local config = colors.get_item_colors()

-- Get colors with semantic state (critical, warning, highlighted)
local config = colors.get_item_colors({ state = "warning" })
```

### Custom Events

This configuration registers custom events:

| Event                        | Description                           |
| ---------------------------- | ------------------------------------- |
| `theme_change`               | macOS appearance changed (dark/light) |
| `theme_colors_updated`       | Internal event after colors refresh   |
| `rift_workspace_change`      | Rift workspace switched (PoC)         |
| `rift_refresh`               | Rift needs full refresh (PoC)         |
| `aerospace_workspace_change` | AeroSpace workspace switched (legacy) |
| `aerospace_refresh`          | AeroSpace needs full refresh (legacy) |

### Environment Detection

```lua
local settings = require("lib.settings")

if settings.is_work_machine then
  -- Work-specific items
end
```

## Common Agent Tasks

### Inspecting Current State

```bash
# See all running items
sketchybar --query bar | jq '.items'

# Check if bar is hidden
sketchybar --query bar | jq '.hidden'

# Get current font settings
sketchybar --query defaults | jq '.icon.font, .label.font'
```

### Testing Changes

```bash
# Reload SketchyBar after config changes
sketchybar --reload
```

### Triggering Events Manually

```bash
# Trigger theme refresh
sketchybar --trigger theme_colors_updated

# Trigger AeroSpace refresh
sketchybar --trigger aerospace_refresh
```

### Setting Item Properties Dynamically

```bash
# Hide an item
sketchybar --set right.battery drawing=off

# Change label text
sketchybar --set right.clock label="Testing"

# Animate a property change
sketchybar --animate ease_out 0.3 --set right.clock label.color=0xffff0000
```

## Debugging Tips

1. **Check console output**: Run `sketchybar` in terminal to see Lua print statements
2. **Query frequently**: Use `--query` to inspect current state before and after changes
3. **Test in isolation**: Comment out items in `items/init.lua` to isolate issues
4. **Watch for typos**: Item names are case-sensitive and must match exactly
5. **Verify events**: Use `sketchybar --query events` to confirm event registration
6. **Check socket**: AeroSpace integration uses Unix socket at `/tmp/bobko.aerospace-<user>.sock`

## Dependencies

- **SbarLua**: Lua bindings for SketchyBar (`~/.local/share/sketchybar_lua/sketchybar.so`)
- **rift.lua**: Lua bindings for Rift Mach IPC (`~/.local/share/rift.lua/rift.so`) - PoC
- **luaposix**: POSIX bindings for AeroSpace socket communication (legacy)
- **cjson**: JSON encoding/decoding
- **simdjson**: Fast JSON parsing (with fallback to cjson)
- **sketchybar-app-font**: App icon font for workspace indicators

## Window Manager Integration

### Rift (PoC)

Rift integration uses Mach IPC via `rift.lua` for querying workspace state, and CLI subscriptions for event-driven updates:

```bash
# Set up SketchyBar triggers (done automatically via Rift's run_on_start)
rift-cli subscribe cli --event workspace_changed --command sh --args -c --args 'sketchybar --trigger rift_workspace_change RIFT_SPACE_ID="$RIFT_SPACE_ID" RIFT_DISPLAY_UUID="$RIFT_DISPLAY_UUID" RIFT_WORKSPACE_NAME="$RIFT_WORKSPACE_NAME"'
rift-cli subscribe cli --event windows_changed --command sh --args -c --args 'sketchybar --trigger rift_windows_change RIFT_SPACE_ID="$RIFT_SPACE_ID" RIFT_DISPLAY_UUID="$RIFT_DISPLAY_UUID" RIFT_WORKSPACE_NAME="$RIFT_WORKSPACE_NAME"'
```

### AeroSpace (Legacy)

AeroSpace integration uses Unix socket communication via `luaposix`. The socket is at `/tmp/bobko.aerospace-<user>.sock`. Currently disabled in `items/init.lua`.
