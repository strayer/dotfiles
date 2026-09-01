-- items/padding.lua - Gap spacer items between islands
--
-- Islands (brackets and single-item backgrounds) provide no margin of their
-- own; invisible fixed-width items between the clusters create the gaps.
-- Creation order matters: a spacer must be added between the items it
-- separates, so items/init.lua calls add() at the right points.

local settings = require("lib.settings")

local M = {}

--- Add an invisible island gap spacer.
--- Deliberately no `width`: const-width items take a different layout path in
--- SketchyBar that drops their paddings from the flow and yields uneven gaps.
--- A contentless item with plain paddings spaces predictably.
---@param name string Item name (must not match any island bracket regex)
---@param position "left"|"right"
function M.add(name, position)
  -- island_gap is the TOTAL visible gap; split across the two paddings
  local gap = settings.layout.island_gap
  sbar.add("item", name, {
    position = position,
    padding_left = math.ceil(gap / 2),
    padding_right = math.floor(gap / 2),
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
  })
end

return M
