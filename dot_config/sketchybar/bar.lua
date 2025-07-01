-- bar.lua - Bar appearance configuration

local colors = require("lib.colors")

-- Add system theme change event
sbar.add("event", "theme_change", "AppleInterfaceThemeChangedNotification")

-- Configure the bar appearance
sbar.bar({
  position = "top",
  height = 37,
  margin = 5,
  y_offset = 5,
  corner_radius = 0,
  blur_radius = 0,
  color = colors.transparent,
  padding_left = 0,
  padding_right = 0,
})