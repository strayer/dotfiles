-- items/init.lua - Item loader for all bar components

-- Padding items (load first to appear at edges)
require("items.padding")

-- Left side items
require("items.chevron")
require("items.aerospace")
require("items.system_theme")

-- Right side items
require("items.clock")
require("items.volume")
require("items.battery")
require("items.package_updates")
require("items.network")

-- Work-specific items (loaded conditionally)
local settings = require("lib.settings")
if settings.is_work_machine then
  require("items.mealplan")
end

-- Brackets (load last to capture all items matching patterns)
require("items.brackets")
