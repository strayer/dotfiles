-- items/init.lua - Item loader for all bar components
--
-- Creation order defines bar order. Right-positioned items stack leftward
-- (first created = rightmost), so the right side builds outside-in:
-- clock, then badges, then the system cluster. Gap spacers separate islands.

local settings = require("lib.settings")
local gaps = require("items.padding")

-- Left side: chevron island | workspace island
require("items.chevron")
gaps.add("left.gap.chevron_ws", "left")
require("items.rift")
require("items.system_theme")

-- Right side: badge island | system island | clock island
-- (badges leftmost: when they disappear, no double gap can open up between
-- the remaining islands)
require("items.clock")
gaps.add("right.gap.clock_system", "right")
require("items.volume")
require("items.battery")
require("items.package_updates")
require("items.network_type")
require("items.network")

-- Work-specific items (loaded conditionally)
if settings.is_work_machine then
  require("items.mealplan")
end

gaps.add("right.gap.system_badges", "right")
require("items.dock_badges")

-- Islands (init last so the static system island finds its members)
require("items.brackets").init()
