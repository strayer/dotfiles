-- items/system_theme.lua - System theme change handler

local colors = require("lib.colors")

-- Add invisible theme handler item
local theme_handler = sbar.add("item", "left.theme_handler", {
  position = "left",
  drawing = false,
  updates = true,
})

-- Handle theme changes
theme_handler:subscribe("theme_change", function()
  -- Update colors module first
  colors.update_theme_colors()

  -- Then trigger a custom event for items to update
  sbar.trigger("theme_colors_updated")
end)
