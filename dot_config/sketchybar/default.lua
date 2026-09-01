-- default.lua - Default item styling

local colors = require("lib.colors")
local settings = require("lib.settings")

-- Set default styling for all items
sbar.default({
  updates = "when_shown",
  padding_left = settings.paddings.item_left,
  padding_right = settings.paddings.item_right,
  icon = {
    font = {
      family = settings.font.text,
      style = "Bold",
      size = 14.0,
    },
    color = colors.get_colors().item_primary,
    padding_left = settings.paddings.icon_left,
    padding_right = settings.paddings.icon_right,
    -- PragmataPro renders ~1pt below the geometric center (measured on
    -- screen); texts using the app-icons font pin y_offset back to 0
    y_offset = 1,
  },
  label = {
    font = {
      family = settings.font.text,
      style = "Bold",
      size = 14.0,
    },
    color = colors.get_colors().item_primary,
    padding_left = settings.paddings.label_left,
    padding_right = settings.paddings.label_right,
    y_offset = 1,
  },
  background = {
    color = colors.get_colors().item_background,
    corner_radius = 5,
    height = 25,
    drawing = true,
  },
  blur_radius = 30,
})
