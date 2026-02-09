-- items/network_type.lua - Network connection type indicator
-- Shows current network type (ethernet, wifi, hotspot, disconnected)
-- Uses a long-running Swift daemon that watches SCDynamicStore for changes

local icons = require("lib.icons")
local colors = require("lib.colors")

local network_icons = icons.system.network_type

-- Register custom event for network state changes
sbar.add("event", "network_info_change")

-- Add network type item to right side
local network_type = sbar.add("item", "right.network_type", {
  position = "right",
  icon = {
    string = network_icons.disconnected,
  },
  label = {
    drawing = false,
  },
})

-- Kill any existing watcher and start a new one
local watcher_bin = os.getenv("HOME")
  .. "/.bin/sketchybar-network-watcher.app/Contents/MacOS/sketchybar-network-watcher"
sbar.exec("sh -c 'pkill -x sketchybar-network-watcher; " .. watcher_bin .. " &'")

-- Update display based on network info change event
local function update_network_type(env)
  local net_type = env.NETWORK_TYPE or "disconnected"
  local ssid = env.NETWORK_SSID or ""

  local state = nil
  if net_type == "disconnected" then
    state = "critical"
  end

  local config = colors.get_item_colors({ state = state })
  config.icon.string = network_icons[net_type] or network_icons.disconnected

  -- Show SSID as label when on wifi or hotspot
  if (net_type == "wifi" or net_type == "hotspot") and ssid ~= "" then
    config.label.drawing = true
    config.label.string = ssid
  else
    config.label.drawing = false
  end

  network_type:set(config)
end

-- Update colors on theme change
local function update_theme()
  local config = colors.get_item_colors()
  network_type:set(config)
end

-- Subscribe to events
network_type:subscribe("network_info_change", update_network_type)
network_type:subscribe("theme_colors_updated", update_theme)
