-- items/init.lua - Item loader for all bar components

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
