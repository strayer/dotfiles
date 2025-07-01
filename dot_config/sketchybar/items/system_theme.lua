-- items/system_theme.lua - System theme change handler

local colors = require("lib.colors")

-- Add invisible theme handler item
local theme_handler = sbar.add("item", "theme_handler", {
  position = "left",
  drawing = false,
  updates = true,
})

-- Handle theme changes
theme_handler:subscribe("theme_change", function()
  -- Update colors module
  colors.update_theme_colors()
  
  -- Force update all items by triggering a forced update
  sbar.trigger("forced")
end)