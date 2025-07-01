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
      size = 14.0
    },
    color = colors.get_colors().item_primary,
    padding_left = settings.paddings.icon_left,
    padding_right = settings.paddings.icon_right,
  },
  label = {
    font = {
      family = settings.font.text,
      style = "Bold", 
      size = 14.0
    },
    color = colors.get_colors().item_primary,
    padding_left = settings.paddings.label_left,
    padding_right = settings.paddings.label_right,
  },
  background = {
    color = colors.get_colors().item_background,
    corner_radius = 5,
    height = 25,
    drawing = true,
  },
  blur_radius = 30,
})