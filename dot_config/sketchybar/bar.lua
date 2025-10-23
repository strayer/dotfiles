-- bar.lua - Bar appearance configuration

local colors = require("lib.colors")
local settings = require("lib.settings")

-- Add system theme change event
sbar.add("event", "theme_change", "AppleInterfaceThemeChangedNotification")

-- Configure the bar appearance (transparent for two-pill layout)
sbar.bar({
  position = "top",
  height = settings.layout.bar_height,
  margin = 0,
  y_offset = settings.layout.bar_y_offset,
  corner_radius = 0,
  blur_radius = 0,
  color = colors.transparent,
  padding_left = settings.layout.bar_padding_h,
  padding_right = settings.layout.bar_padding_h,
})
