-- icons.lua - App icon mapping for SBarLua
-- Imports upstream icon_map and extends with custom mappings

local M = {}

-- Import upstream icon map from sketchybar-app-font
local app_icons = require("lib.3rdparty.icon_map")

-- Custom additions for Beta/Preview versions and other local apps
local custom_icons = {
  ["Brave Browser Beta"] = ":brave_browser:",
  ["Element X"] = ":element:",
  ["Thunderbird Beta"] = ":thunderbird:",
  ["Zed Preview"] = ":zed:",
}

-- Merge custom icons into app_icons (custom takes precedence)
for k, v in pairs(custom_icons) do
  app_icons[k] = v
end

-- System and UI icons
M.system = {
  chevron = "",
  clock = "",
  volume = {
    high = "󰕾",
    medium = "󰖀",
    low = "󰕿",
    muted = "󰖁",
  },
  battery = {
    charging = "󰂄",
    full = "󰁹",
    high = "󰂂",
    medium = "󰁿",
    low = "󰁻",
    critical = "󰁺",
  },
  network = "󰖩",
  network_ping = "",
  network_type = {
    ethernet = "󰈀",
    wifi = "󰖩",
    hotspot = "󱄙",
    disconnected = "󰖪",
  },
  package_updates = "󰏔",
  warning = "󰀪",
  error = "󰅖",
}

-- Function to get app icon
function M.get_app_icon(app_name)
  return app_icons[app_name] or ":default:"
end

-- Function to get all app icons (for debugging)
function M.get_all_app_icons()
  return app_icons
end

return M
