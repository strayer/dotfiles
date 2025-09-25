-- bar.lua - Bar appearance configuration

local colors = require("lib.colors")

-- Add system theme change event
sbar.add("event", "theme_change", "AppleInterfaceThemeChangedNotification")

-- Configure the bar appearance (sun shade style)
sbar.bar({
  position = "top",
  height = 38,
  margin = 0,
  y_offset = 0,
  corner_radius = 0,
  blur_radius = 30,
  color = colors.with_alpha(0x000000, 0.3),
  padding_left = 10,
  padding_right = 10,
})
