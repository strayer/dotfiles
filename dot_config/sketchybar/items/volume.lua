-- items/volume.lua - Volume display with Unicode progress bar

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")

-- Add volume item to right side
local volume = sbar.add("item", "volume", {
  position = "right",
  icon = {
    padding_left = 5,
  },
})

-- Handle volume change events (like original shell script)
local function handle_volume_change(env)
  local volume_level = tonumber(env.INFO)
  if not volume_level then
    return
  end
  
  -- Determine volume icon based on volume level (like original shell script)
  local volume_icon = icons.system.volume.muted
  if volume_level >= 60 then
    volume_icon = icons.system.volume.high
  elseif volume_level >= 30 then
    volume_icon = icons.system.volume.medium
  elseif volume_level >= 1 then
    volume_icon = icons.system.volume.low
  else -- volume_level == 0
    volume_icon = icons.system.volume.muted
  end
  
  -- Generate progress bar or empty label (like original shell script)
  local bar_label = ""
  if volume_level > 0 then
    local progress_bar = utils.generate_unicode_bar(volume_level, 8)
    bar_label = progress_bar .. " " .. volume_level .. "%"
  end
  
  -- Set icon and label with appropriate padding (like original shell script)
  if bar_label == "" then
    -- No label - extra icon padding
    volume:set({
      icon = {
        string = volume_icon,
        padding_right = 7,
      },
      label = {
        drawing = false,
      },
    })
  else
    -- Has label - normal icon padding
    volume:set({
      icon = {
        string = volume_icon,
        padding_right = 4,
      },
      label = {
        string = bar_label,
        drawing = true,
      },
    })
  end
end

-- Subscribe to events
volume:subscribe("volume_change", handle_volume_change)
volume:subscribe("theme_colors_updated", function()
  volume:set(colors.get_item_colors())
end)

-- No initial update needed - volume_change events will trigger updates