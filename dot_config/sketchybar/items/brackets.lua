-- items/brackets.lua - Pill-style brackets for left and right side items

local colors = require("lib.colors")
local settings = require("lib.settings")

local M = {}

local function get_bracket_config()
  return {
    background = {
      color = colors.with_alpha(0x000000, 0.3),
      height = settings.layout.pill_height,
      corner_radius = 9999,
    },
    blur_radius = 30,
  }
end

-- Left pill bracket is created on-demand via refresh_left_bracket()
-- (Rift workspace items are created async, so we can't create the bracket at load time)

-- Create right pill bracket (right-side items are static, so we can create it here)
sbar.add("bracket", "right_pill", { "/right\\..*/" }, get_bracket_config())

-- Track if left bracket exists
local left_bracket_exists = false

--- Create or recreate the left bracket to pick up newly added items
function M.refresh_left_bracket()
  if left_bracket_exists then
    sbar.remove("left_pill")
  end
  sbar.add("bracket", "left_pill", { "/left\\..*/" }, get_bracket_config())
  left_bracket_exists = true
end

--- Recreate the right bracket to pick up newly added items
function M.refresh_right_bracket()
  sbar.remove("right_pill")
  sbar.add("bracket", "right_pill", { "/right\\..*/" }, get_bracket_config())
end

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

return M
