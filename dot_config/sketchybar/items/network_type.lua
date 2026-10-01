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
--
-- On wifi the icon shows the signal level (NETWORK_SIGNAL, 0-4) as bars.
--
-- Hovering opens a details popup. While it is open the daemon is in detail
-- mode (SIGUSR1 on open, SIGUSR2 on close) and sends network_details_change
-- on every link quality event; while closed it gathers no details at all.

local icons = require("lib.icons")
local colors = require("lib.colors")
local known_networks = require("lib.known_networks")

local network_icons = icons.system.network_type

-- Register custom events for network state changes and popup details
sbar.add("event", "network_info_change")
sbar.add("event", "network_details_change")

-- Add network type item to right side
local network_type = sbar.add("item", "right.network_type", {
  position = "right",
  icon = {
    string = network_icons.disconnected,
  },
  label = {
    drawing = false,
  },
  popup = {
    align = "center",
    -- same surface as the bar pills; re-applied in render() on theme changes
    background = {
      color = colors.get_colors().pill_background,
      border_color = colors.get_colors().pill_border,
      border_width = 1,
      corner_radius = 9,
    },
    blur_radius = 30,
    y_offset = 2,
    height = 26, -- row height; unset it falls back to the bar height and rows look double-spaced
  },
})

-- Popup rows, created once and only updated afterwards. Rows without a value
-- are hidden (e.g. the WiFi rows on ethernet, VPN when none is connected).
local ROW_ICONS = {
  network = "󰖩",
  signal = "󰖩",
  rate = "󰓅", -- nf-md-speedometer
  channel = "󰐻", -- nf-md-radio_tower
  phy = "󰘚", -- nf-md-chip
  security = "󰌾", -- nf-md-lock
  ip = "󰩟", -- nf-md-ip_network
  router = "󰑩", -- nf-md-router_network
  vpn = "󰖂", -- nf-md-vpn
}
local ROW_ORDER = { "network", "signal", "rate", "channel", "phy", "security", "ip", "router", "vpn" }

local popup_rows = {}
for _, key in ipairs(ROW_ORDER) do
  popup_rows[key] = sbar.add("item", "network_type.popup." .. key, {
    position = "popup." .. network_type.name,
    icon = {
      string = ROW_ICONS[key],
      width = 24,
      padding_left = 8,
      padding_right = 4,
    },
    label = {
      padding_right = 8,
    },
    padding_left = 4,
    padding_right = 4,
    drawing = false,
  })
end

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
local last_signal = nil
local last_details = {}
local popup_open = false

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
  local signal_icon = last_net_type == "wifi" and last_signal and network_icons.wifi_signal[last_signal + 1]
  config.icon.string = signal_icon or network_icons[last_net_type] or network_icons.disconnected

  if should_show_label(last_net_type, last_ssid, last_hash) then
    config.label.drawing = true
    config.label.string = last_ssid
  else
    config.label.drawing = false
  end

  config.popup = {
    background = {
      color = colors.get_colors().pill_background,
      border_color = colors.get_colors().pill_border,
    },
  }
  network_type:set(config)
end

-- Non-empty env value or nil
local function value(env, name)
  local v = env[name]
  if v == nil or v == "" then
    return nil
  end
  return v
end

-- Popup row texts from a network_details_change env (nil hides the row)
local function detail_rows(env)
  local rows = {}
  local net_type = env.NETWORK_TYPE
  local interface = value(env, "NETWORK_INTERFACE")

  if net_type == "wifi" or net_type == "hotspot" then
    rows.network = value(env, "NETWORK_SSID") or "WiFi"
    if net_type == "hotspot" then
      rows.network = rows.network .. " (hotspot)"
    end
  elseif net_type == "ethernet" then
    rows.network = "Ethernet" .. (interface and (" (" .. interface .. ")") or "")
  end

  local rssi, noise = tonumber(env.NETWORK_RSSI or ""), tonumber(env.NETWORK_NOISE or "")
  if rssi then
    rows.signal = rssi .. " dBm"
    if noise then
      rows.signal = rows.signal .. string.format("  ·  noise %d dBm  ·  SNR %d dB", noise, rssi - noise)
    end
  end
  if value(env, "NETWORK_TX_RATE") then
    rows.rate = env.NETWORK_TX_RATE .. " Mbit/s"
  end
  if value(env, "NETWORK_CHANNEL") then
    rows.channel = "Channel " .. env.NETWORK_CHANNEL
  end
  rows.phy = value(env, "NETWORK_PHY")
  rows.security = value(env, "NETWORK_SECURITY")
  if value(env, "NETWORK_IP") then
    rows.ip = "IP " .. env.NETWORK_IP
  end
  if value(env, "NETWORK_ROUTER") then
    rows.router = "Router " .. env.NETWORK_ROUTER
  end
  if value(env, "NETWORK_VPN") then
    rows.vpn = "VPN " .. env.NETWORK_VPN
  end
  return rows
end

-- Render the popup rows from the cached details
local function render_popup()
  local rows = detail_rows(last_details)
  local primary = colors.get_colors().item_primary
  local level = tonumber(last_details.NETWORK_SIGNAL or "")
  for _, key in ipairs(ROW_ORDER) do
    local row = {
      drawing = rows[key] ~= nil,
      icon = { color = primary },
      label = { string = rows[key] or "", color = primary },
    }
    if key == "network" and last_details.NETWORK_TYPE == "ethernet" then
      row.icon.string = network_icons.ethernet
    elseif key == "network" then
      row.icon.string = network_icons.wifi
    elseif key == "signal" then
      row.icon.string = (level and network_icons.wifi_signal[level + 1]) or ROW_ICONS.signal
    end
    popup_rows[key]:set(row)
  end
end

-- Open/close the popup and switch the daemon's detail mode accordingly
local function set_popup(open)
  if open == popup_open then
    return
  end
  popup_open = open
  network_type:set({ popup = { drawing = open } })
  sbar.exec("pkill -" .. (open and "USR1" or "USR2") .. " -x sketchybar-network-watcher")
end

-- Update display based on network info change event
local function update_network_type(env)
  last_net_type = env.NETWORK_TYPE or "disconnected"
  last_ssid = env.NETWORK_SSID or ""
  last_hash = env.NETWORK_SSID_HASH or ""
  last_signal = tonumber(env.NETWORK_SIGNAL or "")
  render()
  if last_net_type == "disconnected" then
    set_popup(false)
  end
end

local function update_details(env)
  last_details = env
  render_popup()
end

-- Re-render with fresh colors on theme change
local function update_theme()
  render()
  render_popup()
end

-- Subscribe to events
network_type:subscribe("network_info_change", update_network_type)
network_type:subscribe("network_details_change", update_details)
network_type:subscribe("theme_colors_updated", update_theme)
network_type:subscribe({ "mouse.entered", "mouse.exited", "mouse.exited.global" }, function(env)
  set_popup(env.SENDER == "mouse.entered" and last_net_type ~= "disconnected")
end)
