-- items/network.lua - Network ping monitor

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Add network item to right side
local network = sbar.add("item", "network", {
  position = "right",
  icon = {
    drawing = false,
  },
  label = {
    padding_left = 7,
  },
  update_freq = settings.update_freq.network,
})

-- Update network display
local function update_network()
  local ping_command = os.getenv("HOME") .. "/.bin/single-ping 1.1.1.1"

  sbar.exec(ping_command, function(result, exit_code)
    local theme_colors = colors.get_colors()

    if exit_code ~= 0 or not result then
      -- Network error
      network:set({
        label = {
          string = "rtt:???",
          color = theme_colors.critical,
        },
      })
      return
    end

    -- Extract RTT from ping output
    local rtt = result:match("([%d%.]+)ms")
    if rtt then
      local rtt_num = tonumber(rtt)
      local rtt_color = theme_colors.item_primary

      -- Color code based on latency
      if rtt_num > 400 then
        rtt_color = theme_colors.critical
      elseif rtt_num > 200 then
        rtt_color = theme_colors.warning
      end

      network:set({
        label = {
          string = "rtt:" .. result,
          color = rtt_color,
        },
      })
    else
      -- Could not parse RTT
      network:set({
        label = {
          string = "rtt:???",
          color = theme_colors.critical,
        },
      })
    end
  end)
end

-- Subscribe to timer events for automatic updates
network:subscribe("system_woke", update_network)
network:subscribe("routine", update_network)

-- Initial update
update_network()
