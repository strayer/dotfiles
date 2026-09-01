-- items/brackets.lua - Pill-style brackets for left and right side items

local colors = require("lib.colors")
local settings = require("lib.settings")

local M = {}

local function get_bracket_config()
  local theme_colors = colors.get_colors()
  return {
    background = {
      color = theme_colors.pill_background,
      border_color = theme_colors.pill_border,
      border_width = 1,
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
-- (theme_colors_updated fires after lib/colors has refreshed, unlike raw theme_change)
local bracket_handler = sbar.add("item", "bracket_theme_handler", { drawing = false, updates = true })
bracket_handler:subscribe("theme_colors_updated", function()
  local theme_colors = colors.get_colors()
  local bracket_background = {
    color = theme_colors.pill_background,
    border_color = theme_colors.pill_border,
  }

  sbar.set("left_pill", {
    background = bracket_background,
  })

  sbar.set("right_pill", {
    background = bracket_background,
  })
end)

return M
