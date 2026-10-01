-- items/tailscale.lua - Tailscale state indicator with a details popup
-- Only loaded on machines that have a Tailscale CLI (see TAILSCALE_CLIS).
--
-- Icons: dot grid (connected), globe with arrow (connected via an exit node),
-- muted dot square (disconnected / not running). Login needed or health
-- warnings color the icon with the warning color.
--
-- Event-driven: the LaunchAgent earth.gru.sketchybar-tailscale-watch
-- (~/.bin/sketchybar-tailscale-watch, installed by
-- install-sketchybar-tailscale-watch.sh) streams Tailscale's IPN bus and
-- triggers tailscale_change only on state/prefs/netmap/health changes; the
-- item then reads `tailscale status --json` once, and once on load, so a
-- reloaded bar needs no heartbeat. While the popup is
-- open it also refreshes every few seconds for the traffic counters.
-- Clicking does nothing on purpose.

local icons = require("lib.icons")
local colors = require("lib.colors")
local cjson = require("cjson")

local M = { enabled = false }

-- First existing CLI wins: the app's bundled CLI (Standalone/App Store
-- variant, also what /usr/local/bin/tailscale wraps), then Homebrew.
-- Keep in sync with install-sketchybar-tailscale-watch.sh.
local TAILSCALE_CLIS = {
  "/Applications/Tailscale.app/Contents/MacOS/tailscale",
  "/usr/local/bin/tailscale",
  "/opt/homebrew/bin/tailscale",
}

local cli = nil
for _, path in ipairs(TAILSCALE_CLIS) do
  local file = io.open(path, "r")
  if file then
    file:close()
    cli = path
    break
  end
end
if not cli then
  return M
end
M.enabled = true

local POPUP_REFRESH_SECONDS = 5
-- Health messages that are always present on unstable builds and say nothing
-- about the connection
local IGNORED_HEALTH = { "unstable version" }
local MAX_HEALTH_ROWS = 3

sbar.add("event", "tailscale_change")

local tailscale = sbar.add("item", "right.tailscale", {
  position = "right",
  icon = { string = icons.system.tailscale.connected },
  label = { drawing = false },
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

-- Popup rows, created once and only updated afterwards. Rows without text
-- are hidden.
local ROW_ICONS = {
  state = icons.system.tailscale.connected,
  self = "󰩟", -- nf-md-ip
  dns = "󰇖", -- nf-md-dns
  exit = "󰩈", -- nf-md-exit_run
  traffic = "󰓢", -- nf-md-swap_vertical
  peers = "󰀎", -- nf-md-account_multiple
  relay = "󰴽", -- nf-md-transit_connection_variant
  key = "󰌋", -- nf-md-key_variant
  health = "󰗖", -- nf-md-alert_circle_outline
  version = "󰋽", -- nf-md-information_outline
}
local ROW_ORDER = { "state", "self", "dns", "exit", "traffic", "peers", "relay", "key" }
for i = 1, MAX_HEALTH_ROWS do
  table.insert(ROW_ORDER, "health" .. i)
end
table.insert(ROW_ORDER, "version")

local popup_rows = {}
for _, key in ipairs(ROW_ORDER) do
  popup_rows[key] = sbar.add("item", "tailscale.popup." .. key, {
    position = "popup." .. tailscale.name,
    icon = {
      string = ROW_ICONS[key] or ROW_ICONS.health,
      width = 24,
      padding_left = 8,
      padding_right = 4,
    },
    label = { padding_right = 8 },
    padding_left = 4,
    padding_right = 4,
    drawing = false,
  })
end

-- Last parsed status (nil: CLI failed, i.e. Tailscale not running)
local status = nil
local popup_open = false

-- JSON null arrives as cjson.null (userdata) or nil depending on the parser
local function present(v)
  if v == nil or type(v) == "userdata" then
    return nil
  end
  return v
end

local function human_bytes(n)
  local units = { "B", "KB", "MB", "GB", "TB" }
  local i = 1
  while n >= 1000 and i < #units do
    n = n / 1000
    i = i + 1
  end
  return string.format(i == 1 and "%d %s" or "%.1f %s", n, units[i])
end

local function first_ipv4(ips)
  for _, ip in ipairs(present(ips) or {}) do
    if ip:match("^%d+%.%d+%.%d+%.%d+") then
      return ip
    end
  end
  return nil
end

-- Days until an RFC 3339 timestamp (UTC offset ignored, day precision)
local function days_until(timestamp)
  local y, m, d = tostring(timestamp):match("^(%d+)-(%d+)-(%d+)")
  if not y then
    return nil
  end
  local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
  return math.floor((t - os.time()) / 86400)
end

local function health_warnings(s)
  local warnings = {}
  for _, message in ipairs(present(s.Health) or {}) do
    local ignored = false
    for _, pattern in ipairs(IGNORED_HEALTH) do
      if message:find(pattern, 1, true) then
        ignored = true
      end
    end
    if not ignored then
      table.insert(warnings, message)
    end
  end
  return warnings
end

local function exit_node(s)
  for _, peer in pairs(present(s.Peer) or {}) do
    if peer.ExitNode then
      return peer
    end
  end
  return nil
end

local STATE_TEXT = {
  Running = "Connected",
  Stopped = "Disconnected",
  Starting = "Connecting…",
  NeedsLogin = "Login required",
  NeedsMachineAuth = "Waiting for machine approval",
  NoState = "Not running",
}

-- Popup row texts from the current status (nil hides the row)
local function popup_texts()
  local rows = {}
  if not status then
    rows.state = "Tailscale is not running"
    return rows
  end

  local s = status
  local backend = s.BackendState or "NoState"
  local tailnet = present(s.CurrentTailnet) and present(s.CurrentTailnet.Name)
  rows.state = (STATE_TEXT[backend] or backend) .. (tailnet and backend == "Running" and (" to " .. tailnet) or "")

  local version, minor = tostring(s.Version or ""):match("^(%d+%.(%d+)%.%d+)")
  if version then
    rows.version = "Tailscale " .. version .. (tonumber(minor) % 2 == 1 and " (unstable)" or "")
    local client = present(s.ClientVersion)
    if client and client.RunningLatest == false and present(client.LatestVersion) then
      rows.version = rows.version .. "  ·  " .. client.LatestVersion .. " available"
    end
  end

  if backend ~= "Running" then
    return rows
  end

  local self = present(s.Self) or {}
  local ip = first_ipv4(self.TailscaleIPs)
  rows.self = (self.HostName or "?") .. (ip and ("  ·  " .. ip) or "")
  local dns = present(self.DNSName)
  if dns and dns ~= "" then
    rows.dns = dns:gsub("%.$", "")
  end

  local exit = exit_node(s)
  local peers, online, active, exit_options = 0, 0, 0, 0
  for _, peer in pairs(present(s.Peer) or {}) do
    peers = peers + 1
    if peer.Online then
      online = online + 1
    end
    if peer.Active then
      active = active + 1
    end
    if peer.ExitNodeOption and peer.Online then
      exit_options = exit_options + 1
    end
  end

  if exit then
    local path
    if not exit.Online then
      path = "offline"
    elseif present(exit.CurAddr) and exit.CurAddr ~= "" then
      path = "direct"
    else
      path = "via DERP " .. (present(exit.Relay) or "?")
    end
    rows.exit = "Exit node " .. (exit.HostName or "?") .. "  ·  " .. path
    rows.traffic = "↓ " .. human_bytes(exit.RxBytes or 0) .. "   ↑ " .. human_bytes(exit.TxBytes or 0)
  else
    rows.exit = "No exit node" .. (exit_options > 0 and string.format(" (%d available)", exit_options) or "")
  end

  rows.peers = string.format("%d of %d peers online  ·  %d active", online, peers, active)
  if present(self.Relay) and self.Relay ~= "" then
    rows.relay = "Home relay " .. self.Relay
  end

  local expiry = present(self.KeyExpiry)
  if expiry then
    local days = days_until(expiry)
    if days then
      rows.key = days < 0 and "Node key expired" or string.format("Key expires in %d days", days)
    end
  end

  for i, warning in ipairs(health_warnings(s)) do
    if i > MAX_HEALTH_ROWS then
      break
    end
    rows["health" .. i] = #warning > 70 and (warning:sub(1, 69) .. "…") or warning
  end

  return rows
end

local function render()
  local tailscale_icons = icons.system.tailscale
  local icon = tailscale_icons.disconnected
  local state = nil
  local muted = true
  if status then
    local backend = status.BackendState
    if backend == "Running" then
      icon = exit_node(status) and tailscale_icons.exit_node or tailscale_icons.connected
      muted = false
      if #health_warnings(status) > 0 then
        state = "warning"
      end
    elseif backend == "NeedsLogin" or backend == "NeedsMachineAuth" then
      icon = tailscale_icons.connected
      muted = false
      state = "warning"
    end
  end

  local theme = colors.get_colors()
  local config = colors.get_item_colors({ state = state, accent = "tailscale" })
  config.icon.string = icon
  if muted then
    config.icon.color = theme.item_muted
  end
  config.popup = {
    background = {
      color = theme.pill_background,
      border_color = theme.pill_border,
    },
  }
  tailscale:set(config)

  popup_rows.state:set({ icon = { string = icon } })

  local rows = popup_texts()
  for _, key in ipairs(ROW_ORDER) do
    local is_health = key:match("^health")
    popup_rows[key]:set({
      drawing = rows[key] ~= nil,
      icon = { color = is_health and theme.warning or theme.item_primary },
      label = {
        string = rows[key] or "",
        color = (key == "version" or key == "relay") and theme.item_muted or theme.item_primary,
      },
    })
  end
end

-- Read `tailscale status --json`; events arriving mid-read cause one re-read
local refreshing, pending = false, false
local function refresh()
  if refreshing then
    pending = true
    return
  end
  refreshing = true
  sbar.exec(cli .. " status --json 2>/dev/null", function(result)
    if type(result) == "string" then
      local ok, decoded = pcall(cjson.decode, result)
      result = ok and decoded or nil
    end
    status = type(result) == "table" and result.BackendState and result or nil
    render()
    refreshing = false
    if pending then
      pending = false
      refresh()
    end
  end)
end

local function set_popup(open)
  if open == popup_open then
    return
  end
  popup_open = open
  -- routine refreshes only while open, for the exit node traffic counters
  tailscale:set({
    popup = { drawing = open },
    update_freq = open and POPUP_REFRESH_SECONDS or 0,
  })
  if open then
    refresh()
  end
end

tailscale:subscribe("tailscale_change", refresh)
tailscale:subscribe("system_woke", refresh)
tailscale:subscribe("routine", function()
  if popup_open then
    refresh()
  end
end)
tailscale:subscribe("theme_colors_updated", render)
tailscale:subscribe({ "mouse.entered", "mouse.exited", "mouse.exited.global" }, function(env)
  set_popup(env.SENDER == "mouse.entered")
end)

refresh()

return M
