-- items/clock.lua - Date and time display

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Add clock item to right side
local clock = sbar.add("item", "clock", {
  position = "right",
  icon = {
    string = icons.system.clock,
  },
  update_freq = settings.update_freq.clock,
})

-- Update clock display
local function update_clock()
  local date, time = utils.format_time()
  local item_colors = colors.get_item_colors()
  -- Preserve the time string content
  item_colors.label.string = date .. " " .. time
  clock:set(item_colors)
end

-- Initial update
update_clock()

-- Subscribe to timer events for automatic updates
clock:subscribe("system_woke", update_clock)
clock:subscribe("routine", update_clock)
clock:subscribe("theme_colors_updated", update_clock)
