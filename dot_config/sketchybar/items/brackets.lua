-- items/brackets.lua - Pill-style brackets for left and right side items

local colors = require("lib.colors")
local settings = require("lib.settings")

-- Create left pill bracket
sbar.add("bracket", "left_pill", { "/left\\..*/" }, {
  background = {
    color = colors.with_alpha(0x000000, 0.3),
    height = settings.layout.pill_height,
    corner_radius = 9999,
  },
  blur_radius = 30,
})

-- Create right pill bracket
sbar.add("bracket", "right_pill", { "/right\\..*/" }, {
  background = {
    color = colors.with_alpha(0x000000, 0.3),
    height = settings.layout.pill_height,
    corner_radius = 9999,
  },
  blur_radius = 30,
})

-- Subscribe to theme changes to update bracket colors
-- Use a hidden item to handle theme changes for brackets
local bracket_handler = sbar.add("item", "bracket_theme_handler", { drawing = false })
bracket_handler:subscribe("theme_change", function()
  local bracket_color = colors.with_alpha(0x000000, 0.3)

  sbar.set("left_pill", {
    background = { color = bracket_color },
  })

  sbar.set("right_pill", {
    background = { color = bracket_color },
  })
end)
