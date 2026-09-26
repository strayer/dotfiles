-- items/network_type.lua - Network connection type indicator
-- Shows current network type (ethernet, wifi, hotspot, disconnected)
-- Uses a long-running Swift daemon that watches SCDynamicStore for changes
--
-- The SSID label is only shown when the network is not a known one:
-- - wifi on one of this device's default networks          -> icon only
-- - hotspot on one of this device's known hotspot devices -> icon only
-- - any other wifi/hotspot                                -> icon + SSID label
-- Known networks are matched by NETWORK_SSID_HASH (a salted HMAC-SHA256 of
-- the SSID, keyed by ~/.config/dotfiles/hash-salt) against
-- lib/known_networks.lua, so no plain SSIDs live in the repo.
-- Ethernet and disconnected never show a label; an empty SSID (no Location
-- permission) shows no label either.

local icons = require("lib.icons")
local colors = require("lib.colors")
local known_networks = require("lib.known_networks")

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

-- Kill any existing watcher and start a new one. The daemon re-sends its
-- initial state after 2 s because this runs before SbarLua commits the
-- item's subscriptions, so its first trigger could otherwise be lost.
local watcher_bin = os.getenv("HOME")
  .. "/.bin/sketchybar-network-watcher.app/Contents/MacOS/sketchybar-network-watcher"
sbar.exec("sh -c 'pkill -x sketchybar-network-watcher; " .. watcher_bin .. " &'")

-- Last received network state, re-rendered on theme changes
local last_net_type = "disconnected"
local last_ssid = ""
local last_hash = ""

-- Whether the SSID label should be shown for the given network state
local function should_show_label(net_type, ssid, hash)
  if ssid == "" then
    return false
  end
  if net_type == "wifi" then
    return not known_networks.is_default_wifi(hash)
  end
  if net_type == "hotspot" then
    return not known_networks.is_known_hotspot(hash)
  end
  return false
end

-- Render the item from the cached network state
local function render()
  local state = nil
  if last_net_type == "disconnected" then
    state = "critical"
  end

  local config = colors.get_item_colors({ state = state, accent = "network_type" })
  config.icon.string = network_icons[last_net_type] or network_icons.disconnected

  if should_show_label(last_net_type, last_ssid, last_hash) then
    config.label.drawing = true
    config.label.string = last_ssid
  else
    config.label.drawing = false
  end

  network_type:set(config)
end

-- Update display based on network info change event
local function update_network_type(env)
  last_net_type = env.NETWORK_TYPE or "disconnected"
  last_ssid = env.NETWORK_SSID or ""
  last_hash = env.NETWORK_SSID_HASH or ""
  render()
end

-- Re-render with fresh colors on theme change
local function update_theme()
  render()
end

-- Subscribe to events
network_type:subscribe("network_info_change", update_network_type)
network_type:subscribe("theme_colors_updated", update_theme)
