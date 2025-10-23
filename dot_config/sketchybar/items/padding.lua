-- items/padding.lua - Padding items for visual separation in pills

local settings = require("lib.settings")

-- Add left padding item (creates space between pill edge and first item)
sbar.add("item", "left.padding", {
  position = "left",
  width = settings.layout.pill_inner_padding,
  background = { drawing = false },
})

-- Add right padding item (creates space between pill edge and first item)
sbar.add("item", "right.padding", {
  position = "right",
  width = settings.layout.pill_inner_padding,
  background = { drawing = false },
})
