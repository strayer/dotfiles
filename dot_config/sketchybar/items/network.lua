-- items/network.lua - Network ping monitor

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

local PING_TARGET = "1.1.1.1"
local PING_TIMEOUT = 2

local network = sbar.add("item", "right.network", {
  position = "right",
  icon = { string = icons.system.network_ping },
  update_freq = settings.update_freq.network,
})

local function update_network()
  network:set({ label = { string = "…" } })

  sbar.exec("ping -c 1 -t " .. PING_TIMEOUT .. " " .. PING_TARGET, function(result, exit_code)
    local state, label_text

    if exit_code ~= 0 or not result then
      state = "critical"
      label_text = "???"
    else
      local rtt = result:match("time=([%d%.]+)")
      if rtt then
        local rtt_num = tonumber(rtt)
        label_text = string.format("%.0fms", rtt_num)
        if rtt_num > 400 then
          state = "critical"
        elseif rtt_num > 200 then
          state = "warning"
        end
      else
        state = "critical"
        label_text = "???"
      end
    end

    local config = colors.get_item_colors({ state = state })
    config.label.string = label_text
    network:set(config)
  end)
end

network:subscribe("system_woke", function()
  update_network()
  sbar.exec("sleep 3", function()
    update_network()
  end)
  sbar.exec("sleep 8", function()
    update_network()
  end)
end)

network:subscribe("routine", update_network)
network:subscribe("theme_colors_updated", update_network)

update_network()
