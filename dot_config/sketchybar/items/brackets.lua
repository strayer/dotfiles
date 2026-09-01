-- items/brackets.lua - Island brackets (clustered-island layout)
--
-- Multi-item clusters get a bracket island: the workspace island (layout mode
-- + workspace items, dynamic), the system island (stats, static) and the
-- badge island (Dock badges, dynamic). Single-item islands (chevron, clock)
-- don't need brackets - they paint island_background() on their own item.
--
-- Requiring this module has no side effects; items/init.lua calls M.init()
-- after all items exist.

local colors = require("lib.colors")
local settings = require("lib.settings")

local M = {}

--- Background config shared by all islands (also used by single-item islands)
function M.island_background()
  local theme_colors = colors.get_colors()
  return {
    color = theme_colors.pill_background,
    border_color = theme_colors.pill_border,
    border_width = 1,
    height = settings.layout.pill_height,
    corner_radius = 9999,
  }
end

local function island_config()
  return {
    background = M.island_background(),
    blur_radius = 30,
  }
end

-- Brackets resolve their member regex only at creation, so dynamic islands
-- are removed and recreated whenever membership changes.
local workspace_island_exists = false
local badge_island_exists = false

--- Recreate the workspace island to pick up newly created workspace items
function M.refresh_workspace_island()
  if workspace_island_exists then
    sbar.remove("workspace_island")
  end
  -- SketchyBar's bracket regex has no alternation support, and a pattern that
  -- matches nothing makes the whole SbarLua bracket add fail - so one pattern
  -- per rift naming scheme (both always match once workspace items exist).
  sbar.add("bracket", "workspace_island", {
    "/left\\.space\\..*/",
    "/left\\.rift_layout\\..*/",
  }, island_config())
  workspace_island_exists = true
end

--- Recreate the badge island, or remove it entirely when no badges exist
---@param has_badges boolean
function M.refresh_badge_island(has_badges)
  if badge_island_exists then
    sbar.remove("badge_island")
    badge_island_exists = false
  end
  if has_badges then
    -- SketchyBar compiles POSIX *basic* regex (regcomp flags = 0), so only
    -- ".*" works - "+", "|" and "()" are literals. The trailing "\..*"
    -- excludes the hidden "right.dock_badges" anchor item itself.
    sbar.add("bracket", "badge_island", { "/right\\.dock_badges\\..*/" }, island_config())
    badge_island_exists = true
  end
end

--- Create the static islands and the theme handler. Call after all items exist.
function M.init()
  local system_members = {
    "right.volume",
    "right.battery",
    "right.package_updates",
    "right.network_type",
    "right.network",
  }
  if settings.is_work_machine then
    table.insert(system_members, "right.mealplan")
  end
  sbar.add("bracket", "system_island", system_members, island_config())

  -- theme_colors_updated fires after lib/colors has refreshed, unlike raw theme_change
  local handler = sbar.add("item", "bracket_theme_handler", { drawing = false, updates = true })
  handler:subscribe("theme_colors_updated", function()
    local background = M.island_background()
    sbar.set("system_island", { background = background })
    if workspace_island_exists then
      sbar.set("workspace_island", { background = background })
    end
    if badge_island_exists then
      sbar.set("badge_island", { background = background })
    end
  end)
end

return M
