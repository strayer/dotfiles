-- items/battery.lua - Battery display with smart hiding and progress bar

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Add battery item to right side
local battery = sbar.add("item", "right.battery", {
  position = "right",
  update_freq = settings.update_freq.battery,
  updates = true,
})

-- Update battery display
local function update_battery()
  sbar.exec("pmset -g batt", function(result, exit_code)
    if exit_code ~= 0 or not result then
      return
    end

    -- Parse battery percentage
    local battery_percent = result:match("(%d+)%%")
    if not battery_percent then
      return
    end

    battery_percent = tonumber(battery_percent)

    -- Hide battery if > 95% (like original shell script)
    if battery_percent > 95 then
      battery:set({ drawing = false })
      return
    end

    -- Show battery if <= 95%
    battery:set({ drawing = true })

    -- Determine state based on battery percentage
    local state = nil
    if battery_percent <= 15 then
      state = "critical"
    elseif battery_percent <= 45 then
      state = "warning"
    end

    -- Determine battery icon based on percentage ranges (like original)
    local battery_icon = icons.system.battery.critical
    if battery_percent >= 90 then
      battery_icon = icons.system.battery.full
    elseif battery_percent >= 60 then
      battery_icon = icons.system.battery.high
    elseif battery_percent >= 30 then
      battery_icon = icons.system.battery.medium
    elseif battery_percent >= 10 then
      battery_icon = icons.system.battery.low
    end

    -- Check charging status and override state if charging
    local is_charging = result:find("AC Power") ~= nil
    if is_charging then
      battery_icon = icons.system.battery.charging
      state = nil -- Reset to normal state when charging
    end

    -- Generate progress bar
    local progress_bar = utils.generate_unicode_bar(battery_percent, 8)

    -- Get base colors with state
    local config = colors.get_item_colors({ state = state })
    -- Add battery-specific properties
    utils.merge_tables(config, {
      icon = { string = battery_icon },
      label = { string = progress_bar .. " " .. battery_percent .. "%" },
    })
    battery:set(config)
  end)
end

-- Subscribe to events
battery:subscribe("power_source_change", update_battery)
battery:subscribe("system_woke", update_battery)
battery:subscribe("routine", update_battery)
battery:subscribe("theme_colors_updated", update_battery)

-- Initial update
update_battery()
