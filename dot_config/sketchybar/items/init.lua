-- items/init.lua - Item loader for all bar components

local settings = require("lib.settings")

-- Padding items (load first to appear at edges)
require("items.padding")

-- Left side items
require("items.chevron")
if settings.window_manager == "omniwm" then
  require("items.omniwm")
elseif settings.window_manager == "rift" then
  require("items.rift")
end
require("items.system_theme")

-- Right side items
require("items.clock")
require("items.volume")
require("items.battery")
require("items.package_updates")
require("items.network_type")
require("items.network")

-- Work-specific items (loaded conditionally)
if settings.is_work_machine then
  require("items.mealplan")
end

-- Brackets (load last to capture all items matching patterns)
require("items.brackets")
