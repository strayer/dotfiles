-- items/clock.lua - Date and time display (single-item island)

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")
local brackets = require("items.brackets")

-- Add clock item to right side
local clock = sbar.add("item", "right.clock", {
  position = "right",
  -- Single-item island: unlike brackets, the pill (item background) excludes
  -- item paddings, so the gap-side padding would stack onto the island gap.
  -- Keep only the screen-edge side.
  padding_left = 0,
  padding_right = 5,
  icon = {
    string = icons.system.clock,
    -- wider inner paddings keep the content off this island's rounded ends
    padding_left = 12,
  },
  label = {
    padding_right = 12,
  },
  update_freq = settings.update_freq.clock,
})

-- Update clock display
local function update_clock()
  local date, time = utils.format_time()
  local item_colors = colors.get_item_colors({ accent = "clock" })
  -- Preserve the time string content
  item_colors.label.string = date .. " " .. time
  -- The clock is its own island: paint the island surface on the item itself
  item_colors.background = brackets.island_background()
  clock:set(item_colors)
end

-- Initial update
update_clock()

-- Subscribe to timer events for automatic updates
clock:subscribe("system_woke", update_clock)
clock:subscribe("routine", update_clock)
clock:subscribe("theme_colors_updated", update_clock)
